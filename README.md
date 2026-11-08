# Techniix Haiku packages

A Haiku package repository for my Haiku ports. Once it's added, the packages
show up in HaikuDepot and in `pkgman`, and update like any other package.

## Add the repository

On Haiku (x86_64), in Terminal:

```sh
pkgman add-repo https://techniix.github.io/haiku-packages/x86_64/current
```

Then install from HaikuDepot, or with `pkgman install <package>`.

To remove the repository again: `pkgman drop-repo Techniix`.

## Packages

| Package | What it is | Project |
|---|---|---|
| `stardew_valley_haiku` | Launcher and runtime for Stardew Valley (game data must be purchased separately) | [Stardew-Valley_HaikuOS](https://github.com/Techniix/Stardew-Valley_HaikuOS) |

Each package is also attached to its project's GitHub release, if you'd
rather install the `.hpkg` file directly (`pkgman install <file>.hpkg`).

These packages are unofficial and aren't part of Haiku or HaikuPorts. Each
package carries its own licence; see the project pages.

## Maintaining

Packages are built on Haiku with haikuporter from the recipes in each
project's repository. `update-repo.sh` adds them here:

```sh
./update-repo.sh path/to/package-version-revision-x86_64.hpkg
```

It replaces older versions of the same package, rebuilds the `repo` index
with `package_repo`, writes `repo.sha256` and `index.html`, and force-pushes
a single commit so the git history stays small. GitHub Pages serves the
`main` branch.

Layout, as `pkgman` expects it:

```
x86_64/current/repo.info     repository description (name, base URL, architecture)
x86_64/current/repo          package index, generated
x86_64/current/repo.sha256   checksum of repo, generated
x86_64/current/packages/     the .hpkg files
```
