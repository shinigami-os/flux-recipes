# flux-recipes
> Package build recipes for flux.

One directory per package. Recipes are plain text files with `pre-build`, `build`, `post-build`, and `install` hooks, similar in spirit to Arch PKGBUILDs or Void xbps-src templates.

## Structure
```
<package>/
recipe         # main recipe file
patches/       # optional patches applied before build
files/         # optional extra files (configs, scripts)
```

## Contributing
Contribution guidelines will be published once the recipe format is stable. Watch this repo for updates.

## Status
Pre-development. See the [Kira Linux specification](https://github.com/kira-project) and the project roadmap.

## License
GPL-2.0
