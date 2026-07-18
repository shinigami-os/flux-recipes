
/// Kira: fill in the avatar/user labels and build the session pills.
///
/// The pills are just a view over the hidden sessions combo box - clicking one
/// sets that box's active id, so UserSessInfo::extract and the whole login path
/// keep working unchanged and never have to know these exist.
/// Kira: the machine's primary login account, straight out of /etc/passwd.
///
/// regreet normally enumerates users over org.freedesktop.Accounts, but
/// accounts-daemon reports nothing here, which left the combo box empty - and
/// an empty combo box means UserSessInfo::extract hands greetd no user at all,
/// so every login attempt would fail. This box has exactly one human account,
/// so find it directly instead of depending on that service.
fn kira_primary_user() -> Option<(String, String)> {
    let passwd = std::fs::read_to_string("/etc/passwd").ok()?;
    for line in passwd.lines() {
        let f: Vec<&str> = line.split(':').collect();
        if f.len() < 7 {
            continue;
        }
        let Ok(uid) = f[2].parse::<u32>() else {
            continue;
        };
        if !(1000..65000).contains(&uid) {
            continue;
        }
        if f[6].contains("nologin") || f[6].ends_with("false") {
            continue;
        }
        let username = f[0].to_string();
        // GECOS full name if there is one, otherwise just the login name
        let display = match f[4].split(',').next().unwrap_or("").trim() {
            "" => username.clone(),
            name => name.to_string(),
        };
        return Some((username, display));
    }
    None
}

fn kira_decorate(
    model: &Greeter,
    widgets: &GreeterWidgets,
    sender: &AsyncComponentSender<Greeter>,
) {
    let ui = &widgets.ui;

    let mut username = ui
        .usernames_box
        .active_id()
        .map(|s| s.to_string())
        .unwrap_or_default();
    let mut display = ui
        .usernames_box
        .active_text()
        .map(|s| s.to_string())
        .unwrap_or_default();

    if username.is_empty() {
        if let Some((user, disp)) = kira_primary_user() {
            ui.usernames_box.append(Some(&user), &disp);
            ui.usernames_box.set_active_id(Some(&user));
            username = user;
            display = disp;
        }
    }
    if display.is_empty() {
        display = username.clone();
    }

    let initials: String = username.chars().take(2).collect();
    ui.avatar.set_label(&initials);
    ui.user_name.set_label(&display);

    let host = std::fs::read_to_string("/etc/hostname")
        .map(|h| h.trim().to_string())
        .unwrap_or_else(|_| "kira".to_string());
    ui.user_host.set_label(&format!("{username}@{host}"));

    // eg. "7.1.3-shinigami-26.07-4" -> "shinigami 7.1.3 · flux · runit"
    let osrelease = std::fs::read_to_string("/proc/sys/kernel/osrelease").unwrap_or_default();
    let osrelease = osrelease.trim();
    let version = osrelease.split('-').next().unwrap_or_default();
    let kernel = if osrelease.contains("shinigami") {
        "shinigami"
    } else {
        "linux"
    };
    ui.brand_sub
        .set_label(&format!("{kernel} {version} · flux · runit"));

    // HashMap iteration order isn't stable, so without sorting the pills would
    // shuffle around between boots.
    let mut names: Vec<&String> = model.sys_util.get_sessions().keys().collect();
    names.sort();

    let mut pills = Vec::new();
    for session in names {
        let pill = gtk::ToggleButton::with_label(session);
        pill.add_css_class("pill");
        pill.set_focusable(true);
        ui.session_pills.append(&pill);
        pills.push((session.clone(), pill));
    }

    // Upstream only picks a default session inside a `if let Some(initial_username)`
    // block, and that username comes from the user enumeration that turns up
    // empty here - so nothing ever selects one, and a login with no session id
    // has nothing to start. Fall back to the first session.
    if ui.sessions_box.active_id().is_none() {
        if let Some((first, _)) = pills.first() {
            ui.sessions_box.set_active_id(Some(first.as_str()));
        }
    }

    let pills = std::rc::Rc::new(pills);

    for (id, pill) in pills.iter() {
        let id = id.clone();
        let sessions_box = ui.sessions_box.clone();
        let all = pills.clone();
        pill.connect_clicked(move |this| {
            // Clicking the already-selected pill shouldn't deselect it and
            // leave the session unset.
            if !this.is_active() {
                this.set_active(true);
                return;
            }
            sessions_box.set_active_id(Some(&id));
            for (other_id, other) in all.iter() {
                if other_id != &id {
                    other.set_active(false);
                }
            }
        });
    }

    // Keep the pills in step with anything that sets the combo box directly,
    // such as restoring the cached last-used session.
    let all = pills.clone();
    let sync = move |sessions_box: &gtk::ComboBoxText| {
        let active = sessions_box.active_id();
        let active = active.as_ref().map(|s| s.as_str());
        for (id, pill) in all.iter() {
            pill.set_active(Some(id.as_str()) == active);
        }
    };
    sync(&ui.sessions_box);
    ui.sessions_box.connect_changed(move |sb| sync(sb));

    // The password entry only becomes visible once greetd/PAM actually asks for
    // a secret, which upstream triggers by the user clicking Login. This design
    // has no such step - the user should just be able to type - so open the
    // conversation right away and let PAM prompt.
    //
    // Skipped when upstream is about to do its own cached-credentials
    // auto-login below, otherwise the session gets created twice. A later Login
    // (the one carrying the real password) re-sends the session info, so
    // switching pills after the prompt appears still takes effect.
    let upstream_autologin = model.config.skip_selection()
        && model
            .cache
            .get_last_user()
            .map(|user| model.cache.has_last_session(user))
            .unwrap_or(false);

    if !upstream_autologin && !username.is_empty() {
        sender.input(InputMsg::Login {
            input: String::new(),
            info: UserSessInfo::extract(
                &ui.usernames_box,
                &ui.username_entry,
                &ui.sessions_box,
                &ui.session_entry,
            ),
        });
    }
}
