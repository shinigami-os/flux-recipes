# flux-recipes
> kotodama recipes for Kira Linux's own software.

One directory per package, each a plain text `kotodama` file using `[sections]` for declarative metadata and `%hooks` for shell execution blocks. See [flux](https://github.com/shinigami-os/flux) for the package manager these recipes are built by.

## What belongs here

flux resolves every package name by prefix alone: a `kira-`-prefixed name is always built from a recipe in this repo, anything else is always resolved live against [Alpine Linux's package index](https://pkgs.alpinelinux.org/packages). There is no fallback either way, so this repo only ever needs to cover Kira's own software - the distro's meta-packages, its desktop environments, and the rare piece of software genuinely unavailable on Alpine, vendored and renamed to fit the prefix (the Sleex desktop ships as `kira-sleex`, for example).

If Alpine already packages something under its own name, it does not get a recipe here, even if Kira ships it by default - whatever needs it just depends on the Alpine name directly. A `kira-*` recipe's `[deps]` can freely mix `kira-*` names and plain Alpine names in the same list; flux resolves each dependency name by the same prefix rule, recursively, so nothing extra is needed to make that work.

Most recipes here are **thin meta-packages**: an empty `[source]`, a `[deps] runtime` list of the real Alpine packages that make up the feature, and just enough `%install`/`%post-install` to drop Kira-specific config or wire up a runit service. A handful are real from-source builds, for the genuine exceptions Alpine doesn't carry.

## Structure

```
<package>/
  kotodama       # main recipe file
  patches/       # optional patches applied before build
  files/         # optional extra files (configs, scripts)
```

## kotodama format

```ini
[meta]
name = kira-hello
version = 2.12.1
description = "The classic Hello World program"
license = GPL-3.0
size = 1

[source]
url = https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz
sha256 = 8d99142afd92576f30b0cd7cb42a8dc6809998bc5d607d88761f512e26c7db20

[deps]
build = gcc make
runtime =

[build]
cflags = -O2 -pipe -march=x86-64-v2

%pre-build

%build
./configure --prefix=/usr
make

%post-build

%install
make DESTDIR=$DESTDIR install

%post-install
```

### Sections
- `[meta]`: `name` (must match the directory name, and start with `kira-`), `version`, `description`, `license`, `size` (installed size in MB, integer).
- `[source]`: a direct tarball URL and its SHA-256 checksum, a bare single file (a font, copied as-is instead of extracted), or `git+<repo>#<ref>` (shallow-cloned; for a floating branch rather than a tag, `sha256` holds a pinned commit hash instead of a checksum). Leave both `url` and `sha256` empty for a [meta-package](#meta-packages).
- `[deps]`: space-separated `build` and `runtime` lists, each entry either a `kira-*` recipe name or a plain Alpine package name. `build` is only pulled in when the package actually compiles from source; `runtime` is always resolved. A third key, `optional`, shows up in a couple of recipes for nice-to-have extras - flux's parser doesn't recognize it and never resolves it automatically, it's a note to a human reader only. Don't rely on it doing anything.
- `[build]`: optional `cflags`/`ldflags` overrides for the default `-O2 -pipe -march=x86-64-v2`.

### Hooks
- `%pre-build`: patch sources, create directories, pre-compile setup.
- `%build`: configure and compile.
- `%post-build`: tests, cleanup.
- `%install`: install into `$DESTDIR` (flux copies to the live system after).
- `%post-install`: runs only on `flux install`, against the real root, never `$DESTDIR`. For things that aren't files, like creating a system user or enabling a runit service. Never runs during `flux build`.

`set -e` is active in all hooks. Any failed command aborts the build. Every hook also gets `$FLUX_RECIPE_DIR`, the recipe's own directory, for referencing `files/`.

### Meta-packages

Leave `[source]` empty for a recipe that's just a dependency bundle over Alpine packages, optionally with a small `%install` (drop a few config files) or `%post-install` (create a user, enable a runit service). Meta-packages never touch the binary cache, and every build and install re-runs their hooks fresh - this is what lets one pick up a new dependency or a config change on a later install with no version bump needed. Don't put anything expensive in one.

If a meta-package's `%install`/`%post-install` needs files that live in another git repo (like a desktop config repo), pull them with `git clone` or `curl` inside `%build`, into the scratch build directory, instead of checking a static copy into `files/` - a static copy will silently drift out of sync with its real source of truth.

The `kira-desktop-*` packages follow this pattern: each clones the `kira-desktop` repo and copies out of its own lowercase top-level folder (`swayfx/`, `sleex/`) plus the shared `scripts/` directory. A `kira-desktop-<de>` package should only ever read from `<de>/` and `scripts/` in that clone, never from another DE's folder.

## Branches

**`kira-only`** is the live branch - the one `flux update` actually syncs (it's this repo's GitHub default branch, so a plain clone or pull already lands here with no extra configuration). It carries only `kira-*` recipes: everything Alpine already provides directly was trimmed out, since flux resolves those on its own without a recipe.

**`main`** exists only as a history of Kira's recipe set from before the Alpine rewrite - real from-source recipes for software Alpine already packages, kept for reference. Nobody should build against it; it isn't kept in sync and isn't what flux ever fetches.

## Contributing

Read the full kotodama format documentation in the [Kira Linux specification](https://github.com/shinigami-os) before submitting a recipe. Recipes are reviewed before merge and must build cleanly.

Key rules:
- `name` must start with `kira-` and match the directory name exactly - this prefix is the only thing that tells flux to route here instead of to Alpine.
- Before writing a real from-source recipe, check whether Alpine already carries the software (under its own name, or a differently-versioned/split name, e.g. `wlroots` -> `wlroots0.20`, `gtk3` -> `gtk+3.0`). If it does, there's no recipe to add - just depend on the Alpine name directly from whatever needs it.
- For a tarball `url`, `sha256` must be the real checksum of that tarball. `SKIP` is never accepted in the official repo.
- `url` must point directly to a source tarball, a bare single file, or `git+<repo>#<ref>` - never a release page. For a `git+` URL on a floating branch, `sha256` holds a pinned commit hash instead - prefer pinning to a tag when one exists.
- Hooks must use `$DESTDIR` in `%install`, never install directly to `/`.

## Status

`kira-only` (default branch): 43 recipes, covering Kira's own meta-packages, its desktop environments (SwayFX, Sleex), dev-environment bundles, and the handful of from-source builds Alpine doesn't carry. `flux install`, `remove`, `update`, `list`, and `build` (native and `--cross`) are all fully working against this repo.

## License
GPL-2.0
