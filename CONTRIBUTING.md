# Contributing

How to work on the template and its toolchain. For how to *use* it, see
[README.md](README.md).

## Setup

Open the repo in VS Code and choose **Reopen in Container**, or run
`devcontainer up --workspace-folder .`. The dev container builds the image from
this checkout's `Dockerfile`, installs the git hooks and imports the sample
project. Commit from inside it: the hooks call tools that only the image has.

```text
toolchain/            copied into every add-on; `make upgrade` refreshes it
  versions.sh         every tool version, including the Godot branch
  VERSION             `main` here; `make upgrade` writes the release tag
  nest.mk             the shared Make targets
  bin/                install-tools.sh, nest-install-godot, nest-fetch
                      (image build, checksum-checked downloads);
                      nest-doctor, nest-commit-msg, nest-upgrade;
                      nest-package, nest-verify-package (the release zip);
                      install-release-tools, nest-release-prepare (releases)
  verify_package.gd   run by nest-verify-package in a clean project
  readability.mjs     the reading-level check in `make lint`
Dockerfile            builds the dev container and CI image
.github/workflows/    validate.yml, release.yml and godot-patch.yml, the same in
                      every add-on
scripts/init.sh       `make init`: turns a template copy into an add-on
scripts/templates/    the add-on's README.md, CONTRIBUTING.md and .releaserc.json
addons/my_addon/      the sample add-on that `make init` renames
tests/                the sample add-on's tests and the test runner
docs/                 the upgrade guide, copied into every add-on
```

## How it is put together

The template is a working add-on. The repo root has the same layout an add-on
has, so `make check` here tests the toolchain on the sample add-on.

Every add-on is self-contained. "Use this template" copies everything.
`make init` then renames the sample add-on, clears its `.uid` files and
`.godot/`, removes `scripts/`, and writes the three files in
`scripts/templates/`. Other than the renamed sample, its test and its name in
`project.godot`, those are the only files that differ between the template and
an add-on:

- `README.md`. The template's says how to start an add-on; an add-on's
  describes the add-on.
- `CONTRIBUTING.md`. This file describes the toolchain; an add-on's
  describes the add-on.
- `.releaserc.json`. The template's release only tags and publishes notes;
  an add-on's also writes `plugin.cfg` and attaches the zip.

Every other toolchain file, the `Makefile` and all three workflows included, is
the same in the template and in every add-on. An add-on keeps its own Make
targets in `local.mk`.

Upgrades are copies. `nest-upgrade` holds the list of files an add-on takes
from the template. When you add a file outside `toolchain/` that an add-on
needs, add it there and to the list in `scripts/templates/CONTRIBUTING.md`.
`toolchain/` itself is copied whole.

`GODOT_VERSION` in `toolchain/versions.sh` is a major.minor branch, and
`GODOT_RELEASE` is the patch of it that the image installs. `make doctor`
checks that the release is on the branch, and that `project.godot` declares
the branch in `config/features`.

## Comments

Keep a comment when someone might change the line by mistake without it.
Keep it to one to three lines. Otherwise, delete it or move the reason here.
A file's opening comment, with its usage lines, may run longer. Don't tell the
history of a change in a comment. The git log and the release notes keep that.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/),
because semantic-release reads them to choose the next version. The commit-msg
hook and CI both check them. CI also checks pull request titles, since a
squash merge uses the title as the commit message.

| Prefix | Release |
| --- | --- |
| `fix:`, `perf:` or a commit made by `git revert` | Patch: `1.0.0` to `1.0.1` |
| `feat:` | Minor: `1.0.0` to `1.1.0` |
| `feat!:`, `fix!:` or a `BREAKING CHANGE:` footer | Major: `1.0.0` to `2.0.0` |
| `build:`, `chore:`, `ci:`, `docs:`, `refactor:`, `revert:`, `style:`, `test:` | None on their own |

semantic-release treats a revert as a patch only when the body has git's
`This reverts commit <hash>.` line, so use `git revert` rather than writing
`revert:` by hand.

Mark a change as breaking when add-ons must change their own files after
`make upgrade`, such as for a new Godot branch or a removed Make target. Say
what to change in the commit body. [docs/UPGRADING.md](docs/UPGRADING.md)
gets a section for it.

## Testing a change

```bash
make check                                         # in the dev container
# On the host, the way CI runs it, without starting the dev container:
export COMPOSE_FILE=.devcontainer/compose.yaml
export COMPOSE_PROJECT_NAME=godot-addon-nest
docker compose build                               # Windows and macOS
USER_UID="$(id -u)" USER_GID="$(id -g)" docker compose build   # Linux
docker compose run --rm app make check
```

On Linux, the image's `vscode` user is given your user and group IDs, so files
the container writes in the checkout belong to you. Docker Desktop on Windows
and macOS maps file ownership itself, so keep the default IDs there: Git Bash's
`id -u` is not a real Linux ID. In PowerShell, set the variables with
`$env:COMPOSE_FILE = ".devcontainer/compose.yaml"` and
`$env:COMPOSE_PROJECT_NAME = "godot-addon-nest"`. Name the project after the
repo: otherwise every repo's image is called `devcontainer-app`, and
one repo's checks can run in another's image.

To test `make init`, copy the repo somewhere disposable, commit, and run
`make init NAME=example` there. Never run it in this repo. CI does the same on
every Validate run.

## Releasing

Merge Conventional Commits to `main`; there is no release pull request.
When Validate passes on a push to `main`, the Release workflow runs
[semantic-release](https://github.com/semantic-release/semantic-release),
configured in `.releaserc.json`. If the new commits call for a release, it
tags `vX.Y.Z` and publishes a GitHub release with the release notes. It
pushes only the tag, never a commit, with the default `GITHUB_TOKEN`. So if
`main` is ever protected, a release needs no other token and no bypass. The
first release is `1.0.0`.

A failed Validate run releases nothing; the next passing push to `main`
releases everything since the last tag. A failed Release run shows under
**Actions > Release**; fix the cause and push, or re-run it if that commit
is still the head of `main`.

New add-ons get the template as it is on `main`. Existing add-ons pick up a
release only when they run `make upgrade`.

## Keeping pins current

| What | How |
| --- | --- |
| GitHub Actions in the workflows | Dependabot, weekly |
| The `Dockerfile` base image | Dependabot, monthly |
| Godot branch (`GODOT_VERSION`) | **Manual**. A new branch is a breaking change, so it makes a major release. See the list below |
| Godot patch release (`GODOT_RELEASE`) | The Godot patch workflow, weekly. It opens a `chore:` pull request and starts Validate on it |
| editorconfig-checker, lefthook, Node.js, markdownlint-cli2, ShellCheck, actionlint, semantic-release and its plugins | **Manual**, in `toolchain/versions.sh`. With ShellCheck, also update `SHELLCHECK_SHA256`: it publishes no checksum file |

A new Godot branch also means updating:

- `GODOT_RELEASE`
- `config/features` in `project.godot`
- the intro, the first Features bullet, the badge and the links in `README.md`
- the examples in `nest-install-godot`
- the badge and the Godot version in `scripts/templates/README.md`
- the Godot version in `scripts/templates/CONTRIBUTING.md`

Dependabot cannot read `versions.sh`, so those pins are updated by hand. Every
add-on has the same Dependabot settings, so it gets its own action and
base-image updates.
