#!/usr/bin/env bash
# Turn a fresh copy of this template into a new add-on repo.
#   make init NAME=lyrebird
# Renames the sample add-on, writes the add-on's README, CONTRIBUTING.md and
# release config, and removes the template's own scripts. Run it once.
set -euo pipefail

name="${1:-}"
if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "NAME must be lowercase snake_case, for example: make init NAME=lyrebird" >&2
    exit 1
fi
if [[ ! -d addons/my_addon || ! -d toolchain ]]; then
    echo "This doesn't look like a fresh copy of godot-addon-nest." >&2
    exit 1
fi

# lyrebird -> Lyrebird, dice_tools -> Dice Tools
title="$(sed -E 's/_/ /g; s/\b([a-z])/\U\1/g' <<< "$name")"
# The GitHub repo name, for badges: origin's, else the add-on name.
repo="$(git remote get-url origin 2> /dev/null | sed -E 's#.*[/:]([^/]+/[^/]+)$#\1#; s#\.git$##' || true)"
repo="${repo:-birdcall-studio/$name}"

in_git() { git rev-parse --is-inside-work-tree > /dev/null 2>&1; }

remove() {
    # -f: a template copy that was never committed has these files staged.
    if in_git; then
        git rm -rqf --ignore-unmatch "$@"
    fi
    rm -rf "$@"
}

if in_git; then
    git mv addons/my_addon "addons/$name"
else
    mv addons/my_addon "addons/$name"
fi
sed -i -e "s/my_addon/$name/g" -e "s/My Addon/$title/g" \
    tests/test_example.gd "addons/$name/plugin.cfg"
sed -i -e "s/my_addon/$name/g" \
    -e "s/^config\/name=.*/config\/name=\"$title\"/" project.godot
# Fresh UIDs: two add-ons from this template must not share any in one game.
find . -name '*.uid' -not -path './.git/*' -delete
# The import cache still maps the sample add-on's paths to the old UIDs.
rm -rf .godot

fill() {
    sed -e "s|@NAME@|$name|g" -e "s|@TITLE@|$title|g" -e "s|@REPO@|$repo|g" \
        "scripts/templates/$1" > "$1"
}
fill README.md
# Use the add-on's copies of these. The template's own copies describe the
# toolchain.
cp scripts/templates/CONTRIBUTING.md CONTRIBUTING.md
cp scripts/templates/.releaserc.json .releaserc.json

# Only the template needs scripts/. Keep toolchain/, the Dockerfile and docs/.
# The new repo builds its own dev container from them, and `make upgrade`
# keeps them up to date.
remove scripts

if in_git; then
    git add -A
fi

echo "Initialised add-on '$name' ($title)."
echo "Next: fill in README.md, and replace LICENSE if this add-on is not MIT."
echo "Set description= (and author= if needed) in addons/$name/plugin.cfg."
echo "Replace the sample core/dice.gd and tests/test_example.gd with your own."
echo "Then run 'make check' and commit everything:"
echo "  git add -A && git commit -m \"chore: initialise $name from godot-addon-nest\""
