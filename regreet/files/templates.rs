// SPDX-FileCopyrightText: 2022 The ReGreet Authors
//
// SPDX-License-Identifier: GPL-3.0-or-later

//! Templates for various GUI components
//!
//! Kira: the layout here is a full replacement of upstream's centred
//! frame-and-grid form. Every widget component.rs references by name still
//! exists with the same type - the ones this design doesn't show live inside
//! `legacy_controls`, which is invisible. They can't just be set_visible(false)
//! individually, because component.rs re-sets `set_visible` on most of them
//! through #[track] handlers; an invisible parent isn't overridden that way.
#![allow(dead_code)] // Silence dead code warnings for UI code that isn't dead

use gtk::prelude::*;
use relm4::{RelmWidgetExt, WidgetTemplate, gtk};

/// Button that ends the greeter (eg. Reboot)
#[relm4::widget_template(pub)]
impl WidgetTemplate for EndButton {
    view! {
        gtk::Button {
            set_focusable: true,
            add_css_class: "destructive-action",
        }
    }
}

/// Label for an entry/combo box
#[relm4::widget_template(pub)]
impl WidgetTemplate for EntryLabel {
    view! {
        gtk::Label {
            set_width_request: 100,
            set_xalign: 1.0,
        }
    }
}

/// Main UI of the greeter
#[relm4::widget_template(pub)]
impl WidgetTemplate for Ui {
    view! {
        gtk::Overlay {
            /// Background image/video
            #[name = "background"]
            gtk::Picture,

            /// Branding, top left
            add_overlay = &gtk::Box {
                set_halign: gtk::Align::Start,
                set_valign: gtk::Align::Start,
                set_orientation: gtk::Orientation::Vertical,
                set_margin_start: 28,
                set_margin_top: 24,
                set_spacing: 2,

                gtk::Label {
                    set_xalign: 0.0,
                    set_use_markup: true,
                    set_label: "<span foreground=\"#aa00ff\">kira</span> linux",
                    add_css_class: "brand",
                },

                #[name = "brand_sub"]
                gtk::Label {
                    set_xalign: 0.0,
                    set_label: "flux · runit",
                    add_css_class: "brand-sub",
                },
            },

            /// Clock, top right
            #[name = "clock_frame"]
            add_overlay = &gtk::Frame {
                set_halign: gtk::Align::End,
                set_valign: gtk::Align::Start,
                set_margin_end: 28,
                set_margin_top: 18,
                add_css_class: "clock",
            },

            /// The actual login area
            add_overlay = &gtk::Box {
                set_halign: gtk::Align::Center,
                set_valign: gtk::Align::Center,
                set_orientation: gtk::Orientation::Vertical,
                set_spacing: 0,

                /// Widget to display messages to the user
                #[name = "message_label"]
                gtk::Label {
                    set_margin_bottom: 24,
                    add_css_class: "greeting",
                },

                /// Avatar tile showing the selected user's initials
                #[name = "avatar"]
                gtk::Label {
                    set_halign: gtk::Align::Center,
                    set_width_request: 96,
                    set_height_request: 96,
                    add_css_class: "avatar",
                },

                /// Selected user's name
                #[name = "user_name"]
                gtk::Label {
                    set_margin_top: 14,
                    add_css_class: "user-name",
                },

                /// user@host, under the name
                #[name = "user_host"]
                gtk::Label {
                    set_margin_top: 2,
                    add_css_class: "user-host",
                },

                /// Password row: prompt caret, entry, submit
                gtk::Box {
                    set_halign: gtk::Align::Center,
                    set_margin_top: 30,
                    set_spacing: 10,
                    add_css_class: "secret-row",

                    gtk::Label {
                        set_label: "❯",
                        add_css_class: "caret",
                    },

                    /// Widget where the user enters a secret
                    #[name = "secret_entry"]
                    gtk::PasswordEntry {
                        set_show_peek_icon: true,
                        set_hexpand: true,
                        set_width_request: 430,
                        set_placeholder_text: Some("password"),
                    },

                    /// Widget where the user enters something visible
                    #[name = "visible_entry"]
                    gtk::Entry {
                        set_hexpand: true,
                        set_width_request: 430,
                    },

                    /// Button to enter the password and login
                    #[name = "login_button"]
                    gtk::Button {
                        set_focusable: true,
                        set_label: "↵",
                        set_receives_default: true,
                        set_valign: gtk::Align::Center,
                        add_css_class: "submit",
                    },
                },

                /// Prompt text under the password row
                #[name = "input_label"]
                gtk::Label {
                    set_margin_top: 16,
                    add_css_class: "hint",
                },

                /// Session pills
                #[name = "session_pills"]
                gtk::Box {
                    set_halign: gtk::Align::Center,
                    set_margin_top: 18,
                    set_spacing: 8,
                    add_css_class: "pills",
                },

                // Everything this design doesn't surface, but component.rs
                // still drives. The parent stays invisible, so the tracked
                // set_visible handlers on the children change nothing on screen.
                #[name = "legacy_controls"]
                gtk::Box {
                    set_visible: false,

                    #[name = "session_label"]
                    #[template]
                    EntryLabel { set_label: "Session:" },

                    #[name = "usernames_box"]
                    gtk::ComboBoxText,

                    #[name = "username_entry"]
                    gtk::Entry,

                    #[name = "sessions_box"]
                    gtk::ComboBoxText,

                    #[name = "session_entry"]
                    gtk::Entry,

                    #[name = "user_toggle"]
                    gtk::ToggleButton {
                        set_icon_name: "document-edit-symbolic",
                    },

                    #[name = "sess_toggle"]
                    gtk::ToggleButton {
                        set_icon_name: "document-edit-symbolic",
                    },

                    #[name = "cancel_button"]
                    gtk::Button {
                        set_label: "Cancel",
                    },
                },
            },

            /// Notification bar for messages
            add_overlay = &gtk::Box {
                set_halign: gtk::Align::Center,
                set_valign: gtk::Align::End,
                set_margin_bottom: 90,

                #[name = "notif_info"]
                gtk::InfoBar {
                    // During init, the info bar closing animation is shown. To hide that, make
                    // it invisible. Later, the code will permanently make it visible, so that
                    // `InfoBar::set_revealed` will work properly with animations.
                    set_visible: false,
                    set_message_type: gtk::MessageType::Info,

                    /// The actual notification message
                    #[name = "notif_label"]
                    gtk::Label {
                        set_halign: gtk::Align::Center,
                        set_margin_top: 8,
                        set_margin_bottom: 8,
                        set_margin_start: 14,
                        set_margin_end: 14,
                    },
                },
            },

            /// Power controls, bottom right
            add_overlay = &gtk::Box {
                set_halign: gtk::Align::End,
                set_valign: gtk::Align::End,
                set_margin_end: 24,
                set_margin_bottom: 22,
                set_spacing: 8,
                add_css_class: "power",

                /// Button to power-off
                #[name = "poweroff_button"]
                #[template]
                EndButton { set_label: "⏻" },

                /// Button to reboot
                #[name = "reboot_button"]
                #[template]
                EndButton { set_label: "⟳" },
            },
        }
    }
}
