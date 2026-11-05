# Contributing

How to work on this add-on. For how to *use* it, see [README.md](README.md).

## Setup

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/), and either
[VS Code](https://code.visualstudio.com/) with the Dev Containers extension or
the [Dev Container CLI](https://github.com/devcontainers/cli).

Open the repo in VS Code and choose **Reopen in Container**, or run
`devcontainer up --workspace-folder .`. The image is built from this repo's
`Dockerfile`. It has headless Godot 4.7 and the linters.
`.devcontainer/compose.yaml` starts the container from that image. The first
build takes a few minutes. On first start, the container installs the git hooks
and imports the project. Rebuild it after you merge a Godot patch pull request.

## Day-to-day workflow

The repo folder on your machine is mounted into the container at
`/workspace`. Edit the files on your machine, and the container's tools see
the change at once. The tools never run on your machine.

- **Writing GDScript.** In VS Code attached to the container, the Godot
  extension starts a headless Godot inside the container for completion and
  errors. Outside VS Code, use any editor on your machine.
- **Scenes, the inspector and running the game.** The container has no
  graphical Godot. Open the same folder in the Godot 4.7 editor installed on
  your machine. It shares the import cache in `.godot/` with the container,
  so keep it on the same Godot version.
- **Checking and committing.** Run Make and git inside the container, where
  the tools and git hooks are:

  ```bash
  devcontainer exec --workspace-folder . make check
  devcontainer exec --workspace-folder . git commit -m "feat: add dice pools"
  devcontainer exec --workspace-folder . bash    # or open a shell there
  ```

  In VS Code, use its terminal, which already runs in the container. VS Code
  also copies in your git name and email. The CLI does not copy them, so set
  them with `devcontainer exec --workspace-folder . git config --global
  user.name "Your Name"`, and do the same for `user.email`. Set them again
  after you rebuild the container. A commit made on your machine skips the
  hooks, so CI is the first to check it.
- **Stopping.** VS Code stops the container when you close the window. With
  the CLI, find the project in `docker compose ls` and run
  `docker compose -p <project> down`.
- **Running the checks the way CI does.** Do this if CI fails but the dev
  container passes. It builds the image without starting the dev container.
  Name the Compose project after this repo. If you don't, every add-on's
  image is called `devcontainer-app`, and one add-on's checks can run in
  another's image. In PowerShell, set the variables with
  `$env:NAME = "value"`. On Linux, pass your user and group IDs so that files
  the container writes belong to you. Windows and macOS can keep the
  defaults:

  ```bash
  export COMPOSE_FILE=.devcontainer/compose.yaml
  export COMPOSE_PROJECT_NAME=<repo name>
  docker compose build                                           # Windows and macOS
  USER_UID="$(id -u)" USER_GID="$(id -g)" docker compose build   # Linux
  docker compose run --rm app make check
  ```

The repo is laid out like this:

```text
addons/<name>/        the add-on: the only folder a game copies
tests/**/test_*.gd    tests, one file per area
tests/support/        the test base class (from the template)
tests/run_tests.gd    the headless test runner (from the template)
project.godot         a test harness for the add-on, never shipped
toolchain/            Make targets and scripts (from the template)
Dockerfile            the dev container and CI image (from the template)
```

Run `make help` for every command. The one that matters is `make check`, which
runs exactly what CI runs. Put this add-on's own Make targets in `local.mk`,
which the `Makefile` includes and `make upgrade` leaves alone.

## Writing code

- Runtime code goes under `addons/<name>/`, outside `plugin.gd`, so it works
  without the editor plugin enabled.
- `project.godot` sets selected GDScript warnings to Error. A warning that
  fires stops the script compiling, in the editor and in `make test` alike.
  Fix the cause; prefix an intentionally unused name with `_`. `make test`
  fails if `project.godot` turns these warnings down or excludes the add-on
  under Debug > GDScript > Directory Rules.
- `make verify-package` opens the zip in a new, empty project with none of
  this repo's tests or settings. An add-on that leans on them fails there,
  before a game finds out.
- Godot's guide to
  [making plugins](https://docs.godotengine.org/en/4.7/tutorials/plugins/editor/making_plugins.html)
  explains `plugin.cfg` and `plugin.gd`.
- Follow Godot's
  [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
  `make lint` checks the indentation, line length and whitespace parts of it.
- Write docs and comments in plain English. `make lint` fails a paragraph or
  comment that reads above grade 12, a high school graduate's level, and
  prints where it is. Split long sentences and use shorter words.

## Writing tests

Add `tests/test_<area>.gd`:

```gdscript
extends "res://tests/support/test_case.gd"


func test_something() -> void:
	check(1 + 1 == 2, "maths should work")
```

Every method named `test_*` in a file named `test_*.gd` anywhere under
`tests/` runs, and may use `await`. `check(condition, message)` records a
failure without stopping the test. A test also fails if it raises any engine
or script error, such as a null reference, a failed `assert()` or
`push_error()`; warnings do not fail it.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/).
semantic-release reads them to choose the next version. The commit-msg hook and
CI both check them. CI also checks pull request titles, since a squash merge
uses the title as the commit message.

| Prefix | Release |
| --- | --- |
| `fix:`, `perf:`, or a commit made by `git revert` | Patch: `1.0.0` to `1.0.1` |
| `feat:` | Minor: `1.0.0` to `1.1.0` |
| `feat!:`, `fix!:` or a `BREAKING CHANGE:` footer | Major: `1.0.0` to `2.0.0` |
| `build:`, `chore:`, `ci:`, `docs:`, `refactor:`, `revert:`, `style:`, `test:` | None on their own |

The first release is `1.0.0`. semantic-release treats a revert as a patch only
when the body has git's `This reverts commit <hash>.` line, so use
`git revert` rather than writing `revert:` by hand.

## Releases

Open a pull request and squash-merge it; there is no release pull request. In
the repo's settings, allow only squash merging, and set the default commit
message to the pull request title. On each push, the Release workflow runs
[semantic-release](https://github.com/semantic-release/semantic-release) once
Validate passes on that push. If the new commits call for a release, it tags
`vX.Y.Z` and publishes a GitHub release with the release notes and
`<name>-vX.Y.Z.zip`.

The zip holds only the add-on folder, with `LICENSE` copied into it and the
version written into its `plugin.cfg`. `make package` builds the same zip
locally, without the version. `make check` tests it in a clean project. The
release pushes only the tag, never a commit, with the default `GITHUB_TOKEN`.

A failed Validate run releases nothing; the next passing push to `main`
releases everything since the last tag. A failed Release run shows under
**Actions > Release**; fix the cause and push, or re-run it if that commit is
still the head of `main`.

Each Monday, the Godot patch workflow opens a `chore:` pull request if a
newer Godot 4.7 patch is out. For this to work, allow GitHub Actions to create
pull requests. Turn this on under **Actions > General** in both the
organisation's and the repo's settings.

The `version=` line in `plugin.cfg` on `main` stays a placeholder; leave it,
since only the zip carries the real version. `make doctor` fails if the line
is missing.

## Toolchain files

These files come from the
[godot-addon-nest](https://github.com/birdcall-studio/godot-addon-nest)
template, at the release in `toolchain/VERSION` (`main` until the first
`make upgrade`):

- `Dockerfile`, `Makefile`, `toolchain/`, `.devcontainer/devcontainer.json`,
  `.devcontainer/compose.yaml`
- `.editorconfig`, `.editorconfig-checker.json`, `.gitattributes`,
  `.markdownlint-cli2.jsonc`, `lefthook.yml`, `.releaserc.json`,
  `CONTRIBUTING.md`, `docs/UPGRADING.md`
- `.github/CODEOWNERS`, `.github/dependabot.yml`,
  `.github/workflows/validate.yml`, `.github/workflows/release.yml`,
  `.github/workflows/godot-patch.yml`
- `tests/run_tests.gd`, `tests/support/test_case.gd`

`make upgrade FROM=<release tag>` replaces them with the copies from that
template release. See [docs/UPGRADING.md](docs/UPGRADING.md). Change them in
the template where you can, so every add-on gets the change; an edit made only
here is overwritten by the next upgrade. Notes about this add-on belong in
`README.md`, and its own Make targets in `local.mk` (see
[Day-to-day workflow](#day-to-day-workflow)).
