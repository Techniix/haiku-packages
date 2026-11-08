#!/bin/bash
# Adds packages to this Haiku package repository and publishes it.
# Run on Haiku (it needs package_repo).
#
#   ./update-repo.sh [--no-push] <package.hpkg>...
#
# Each package replaces older versions of the same package. The repository
# file is then rebuilt with package_repo, and everything is pushed as a
# single commit (force-push), so git history doesn't grow with every
# package version. GitHub Pages serves the result.
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

cd "$(dirname "$(readlink -f "$0")")"
push=1
if [ "${1:-}" = --no-push ]; then push=0; shift; fi
[ $# -gt 0 ] || die "usage: $0 [--no-push] <package.hpkg>..."
command -v package_repo >/dev/null || die "package_repo not found; run this on Haiku."

repo_dir="$PWD/x86_64/current"
mkdir -p "$repo_dir/packages"

added=()
for pkg in "$@"; do
  [ -f "$pkg" ] || die "no such file: $pkg"
  file="$(basename "$pkg")"
  case "$file" in
    *-x86_64.hpkg|*-any.hpkg) ;;
    *) die "$file: only x86_64 (or 'any') packages belong in this repository." ;;
  esac
  name="${file%%-*}"   # package names use underscores, never hyphens
  find "$repo_dir/packages" -name "$name-*.hpkg" ! -name "$file" -print -delete \
    | sed 's|.*/|Removed old version: |'
  cp "$pkg" "$repo_dir/packages/$file"
  echo "Added: $file"
  added+=("$name")
done

shopt -s nullglob
packages=("$repo_dir"/packages/*.hpkg)
[ ${#packages[@]} -gt 0 ] || die "the repository has no packages."
rm -f "$repo_dir/repo" "$repo_dir/repo.sha256"
package_repo create -q "$repo_dir/repo.info" "${packages[@]}"
[ -f "$repo_dir/repo" ] || die "package_repo didn't write $repo_dir/repo."
sha256sum "$repo_dir/repo" | cut -d' ' -f1 > "$repo_dir/repo.sha256"

# Plain package list for browsers (GitHub Pages has no directory listings).
{
  echo "<!DOCTYPE html><meta charset=utf-8><title>Techniix Haiku packages (x86_64)</title>"
  echo "<h1>Techniix Haiku packages (x86_64)</h1>"
  echo "<p>Add this repository on Haiku with:<br><code>pkgman add-repo https://techniix.github.io/haiku-packages/x86_64/current</code></p><ul>"
  for p in "${packages[@]}"; do
    f="$(basename "$p")"
    echo "<li><a href=\"packages/$f\">$f</a></li>"
  done
  echo "</ul>"
} > "$repo_dir/index.html"

[ "$push" = 1 ] || { echo "Repository updated (not pushed)."; exit 0; }

# One parentless commit with the current tree. Built with plumbing so that a
# failure (e.g. no git identity) leaves the branch as it was.
branch="$(git symbolic-ref --short HEAD)"
git add -A
tree="$(git write-tree)"
commit="$(git commit-tree "$tree" -m "Update ${added[*]}")"
git reset -q "$commit"
git push -qf origin "$branch"
git gc -q --prune=now
echo "Published. Haiku picks it up on the next 'pkgman refresh' or update."
