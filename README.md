# flux-recipes
> Package build recipes for flux.

One directory per package. Each recipe is a plain text `kotodama` file using `[sections]` for declarative metadata and `%hooks` for shell execution blocks.

## Structure

```
<package>/
  kotodama       # main recipe file
  patches/       # optional patches applied before build
  files/         # optional extra files (configs, scripts)
```

## kotodama format

```
[meta]
name = hello
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
- `[meta]`: name, version, description, license, size (in MB)
- `[source]`: direct tarball URL and SHA-256 checksum, leave both empty for a meta-package
- `[deps]`: space-separated build and runtime dependency lists
- `[build]`: optional cflags and ldflags overrides

### Hooks
- `%pre-build`: patch sources, create directories, pre-compile setup
- `%build`: configure and compile
- `%post-build`: tests, cleanup
- `%install`: install into `$DESTDIR` (flux copies to the live system after)
- `%post-install`: runs only on `flux install`, against the real root, never `$DESTDIR`. For things that aren't files, like creating a system user. Never runs during `flux build`.

`set -e` is active in all hooks. Any failed command aborts the build.

### Meta-packages

Leave `[source]` empty for a recipe that's just a dependency bundle, optionally with a small `%install` (drop a few config files) or `%post-install` (create a user, a runit service). Meta-packages never touch the binary cache. Every build and install re-runs their hooks fresh, so don't put anything expensive in one.

If a meta-package's `%install`/`%post-install` needs files that live in another git repo (like a desktop config repo), pull them with `git clone` or `curl` inside `%build` into the scratch build directory instead of checking a copy into `files/`. A static copy in `files/` will silently drift out of sync with its source of truth.

The `kira-desktop-*` packages follow this pattern: each clones the `kira-desktop` repo and copies out of its own lowercase top-level folder (`swayfx/`, `sleex/`) plus the shared `scripts/` directory. A `kira-desktop-<de>` package should only ever read from `<de>/` and `scripts/` in that clone, never from another DE's folder.

## Contributing

Read the full kotodama format documentation in the [Kira Linux specification](https://github.com/shinigami-os) before submitting a recipe. Recipes are reviewed before merge. The recipe must build cleanly and pass basic sanity checks before entering the repo.

Key rules:
- `sha256` must be the real checksum of the source tarball. `SKIP` is never accepted in the official repo.
- `url` must point directly to a source tarball, not a release page.
- `name` must match the directory name exactly.
- Hooks must use `$DESTDIR` in `%install`, never install directly to `/`.

## Status

Phase 3. Core recipe format stable, including the `%post-install` hook, meta-packages, and `no_sysroot_stage`. Well over 300 recipes covering the base toolchain, desktop stack (Wayland/wlroots, GTK4, greetd + regreet + cage for the login manager), and common developer tooling. `flux install`, `remove`, `search`, `update`, `info`, `list`, `cache`, and `build` (native and `--cross`) are all fully working against this repo. See the [Kira Linux specification](https://github.com/shinigami-os) and the project roadmap.

## License
GPL-2.0
