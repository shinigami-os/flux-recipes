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
```

### Sections
- `[meta]`: name, version, description, license, size (in MB)
- `[source]`: direct tarball URL and SHA-256 checksum
- `[deps]`: space-separated build and runtime dependency lists
- `[build]`: optional cflags and ldflags overrides

### Hooks
- `%pre-build`: patch sources, create directories, pre-compile setup
- `%build`: configure and compile
- `%post-build`: tests, cleanup
- `%install`: install into `$DESTDIR` (flux copies to the live system after)

`set -e` is active in all hooks. Any failed command aborts the build.

## Contributing

Read the full kotodama format documentation in the [Kira Linux specification](https://github.com/shinigami-os) before submitting a recipe. Recipes are reviewed before merge. The recipe must build cleanly and pass basic sanity checks before entering the repo.

Key rules:
- `sha256` must be the real checksum of the source tarball. `SKIP` is never accepted in the official repo.
- `url` must point directly to a source tarball, not a release page.
- `name` must match the directory name exactly.
- Hooks must use `$DESTDIR` in `%install`, never install directly to `/`.

## Status

Phase 1. Core recipe format stable. `flux install`, `remove`, `search`, `update`, and `info` are fully working against this repo. See the [Kira Linux specification](https://github.com/shinigami-os) and the project roadmap.

## License
GPL-2.0
