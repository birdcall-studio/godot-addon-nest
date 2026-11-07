# godot-addon-nest

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Validate](https://github.com/birdcall-studio/godot-addon-nest/actions/workflows/validate.yml/badge.svg)](https://github.com/birdcall-studio/godot-addon-nest/actions/workflows/validate.yml)
[![Release](https://github.com/birdcall-studio/godot-addon-nest/actions/workflows/release.yml/badge.svg)](https://github.com/birdcall-studio/godot-addon-nest/actions/workflows/release.yml)
[![Godot 4.7](https://img.shields.io/badge/godot-4.7-478cbf.svg)](https://godotengine.org)

The Birdcall Studio template for Godot 4.7 add-ons. Every add-on is built and
released the same way. It uses one Godot version and the same tools on your
machine and in CI.

## Features

- Everything targets the Godot **4.7** stable branch. The image installs one
  pinned patch release. Godot supports only the newest patch, so a weekly
  workflow opens a pull request for each new one.
- Each add-on carries its own copy of the toolchain: a `Dockerfile` with
  headless Godot, the linters and the git hooks, plus the Make targets and
  scripts in `toolchain/`. The dev container and CI both build from that
  `Dockerfile`, so they run the same tools. No shared image or toolchain repo
  is needed, and every tool version is pinned.
- `make upgrade FROM=<tag>` copies that template release's toolchain files
  into an add-on, and you review the diff. See
  [docs/UPGRADING.md](docs/UPGRADING.md).
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/).
  [semantic-release](https://github.com/semantic-release/semantic-release)
  turns them into a version tag and a GitHub release, with release notes and
  the add-on zipped, once `main` passes its checks. There is no release pull
  request and no release commit.
- The checks use Godot itself, editorconfig-checker, markdownlint-cli2,
  ShellCheck and actionlint.

## Start a new add-on

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/), and either
[VS Code](https://code.visualstudio.com/) with the Dev Containers extension or
the [Dev Container CLI](https://github.com/devcontainers/cli).

1. Click **Use this template** and create the repo under `birdcall-studio`.
2. Clone it and start the dev container: **Reopen in Container** in VS Code,
   or `devcontainer up --workspace-folder .`. The first build downloads Godot
   and the tools, which takes a few minutes; later starts reuse it.
3. Run `make init NAME=your_addon` (lowercase snake_case).
4. Make the add-on yours:
   - Fill in `README.md`, and replace `LICENSE` if the add-on is not MIT.
   - In `addons/<name>/plugin.cfg`, set `description=`, and `author=` if it
     is not Birdcall Studio. Leave `version=` alone: a release writes it.
   - Replace the sample `addons/<name>/core/dice.gd` and
     `tests/test_example.gd` with your own. `make test` fails if no test is
     left.
5. In the dev container's terminal, run `make check`. With the Dev Container
   CLI, set your git name and email in the container first, as
   [the add-on's CONTRIBUTING.md](scripts/templates/CONTRIBUTING.md#day-to-day-workflow)
   explains.
6. Commit and push. Include the `.uid` files Godot writes beside each script.

   ```bash
   git add -A
   git commit -m "chore: initialise your_addon from godot-addon-nest"
   git push
   ```

   A `chore:` commit makes no release, so your first `feat:` on `main`
   becomes 1.0.0.
7. In the repo's settings on GitHub, allow only squash merging, and set the
   default commit message to the pull request title. CI checks that title,
   because it becomes the commit on `main` that semantic-release reads.
8. In the organisation's and the repo's **Actions > General** settings, allow
   GitHub Actions to create pull requests. The Godot patch workflow needs it.

`make init` renames the sample add-on, deletes its `.uid` files and the
import cache in `.godot/` so Godot makes fresh ones, writes the add-on's README,
`CONTRIBUTING.md` and release config, and deletes the template's own
`scripts/`. Everything else, including the `Dockerfile` and `toolchain/`,
stays: the add-on builds its own dev container from them.

## Commands

Run these inside the dev container.

| Command | What it does |
| --- | --- |
| `make check` | Doctor, lint, import, test and verify-package: what CI runs |
| `make doctor` | Check there is one add-on folder, `plugin.cfg` has a version, and the Godot branch matches |
| `make lint` | Check `.editorconfig` style rules, Markdown, reading level, workflows (actionlint) and shell scripts (ShellCheck) |
| `make import` | Open the project headless and load the editor plugin, printing any plugin errors |
| `make test` | Check the warning settings, compile every add-on script, then run `tests/**/test_*.gd` |
| `make package` | Zip the add-on's tracked and new files into `dist/<name>-v<version>.zip`, as a release does |
| `make verify-package` | Build that zip, then check it the way a game uses it (see below) |
| `make hooks` | Install the git hooks (the dev container does this) |
| `make clean` | Delete the import cache (`.godot/`) and `dist/` |
| `make upgrade FROM=<tag>` | Copy that template release's toolchain files into this add-on |

A release also writes its version into the zip's `plugin.cfg`; `make package`
keeps the placeholder.

Write tests in `tests/test_<area>.gd`. Extend `res://tests/support/test_case.gd`,
name methods `test_*`, and call `check(condition, message)`. Subfolders of
`tests/` work too. A test also fails if it raises an engine or script error.

## What is checked

| Check | Tool | Where |
| --- | --- | --- |
| UTF-8, LF endings, final newline, no trailing spaces, tabs and a 100-character limit for GDScript ([Godot style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)) | editorconfig-checker | `make lint`, pre-commit hook, CI |
| Markdown style | markdownlint-cli2 | `make lint`, pre-commit hook, CI |
| Every Markdown paragraph and comment reads at grade 12 or below | `toolchain/readability.mjs` | `make lint`, pre-commit hook, CI |
| Workflows and shell scripts | actionlint, ShellCheck | `make lint`, pre-commit hook, CI |
| GDScript problems such as unused variables and unreachable code | Godot, with those warnings set to Error in `project.godot` | `make test`, the editor, CI |
| GDScript warning settings in `project.godot` | Godot | `make test`, CI |
| Commit messages and pull request titles | `nest-commit-msg` | commit-msg hook, CI on pull requests |
| One add-on folder, its `plugin.cfg` version and the Godot branch | `nest-doctor` | `make doctor`, CI |
| The release zip's contents, its `plugin.cfg` fields, and that it works in a new, empty project | `nest-verify-package` | `make verify-package`, CI |

`make verify-package` checks that the zip holds only `addons/<name>/` with a
`LICENSE`, and that `plugin.cfg` has a name, description, author, version and
script. Then, in a new, empty Godot project, the plugin must enable and extend
`EditorPlugin`, and every script must compile, with no errors. The clean
project has none of this repo's tests or project settings, so an add-on that
leans on them fails here before a game finds out.

An Error-level warning stops a script compiling, so it fails in the editor, in
`make test` and in CI alike, including editor-only scripts such as `plugin.gd`.
`make test` also fails if `project.godot` turns those warnings down or
excludes `res://addons` from them.

The reading-level check uses the Flesch-Kincaid grade, which counts only
sentence and word length; code, paths and tool names are left out. Grade 12
is a high school graduate. If a block fails, split long sentences and use
shorter words. `make lint READING_GRADE=10` tries a stricter limit.

Naming conventions and code order are not checked: neither editorconfig-checker
nor Godot understands them.

## CI/CD

The same three workflows run in this template and in every add-on made from it.

| Event | What runs |
| --- | --- |
| Pull request | Build the image from the `Dockerfile` and run `make check` in it; check commit messages and the title |
| Push to `main` | The same `make check`; if it passes, the Release workflow |
| Every Monday | The Godot patch workflow: a pull request if a newer patch of the Godot branch is out |

The Release workflow runs semantic-release. If the new commits call for a
release, it tags `vX.Y.Z` and publishes a GitHub release with its notes. In an
add-on, the release also gets `<name>-vX.Y.Z.zip`.

In this template only, CI also runs `make init` on a copy and checks the
resulting add-on.

## Documentation

- [Godot documentation](https://docs.godotengine.org/en/4.7/), including
  [making plugins](https://docs.godotengine.org/en/4.7/tutorials/plugins/editor/making_plugins.html)
- [Godot release policy](https://docs.godotengine.org/en/stable/about/release_policy.html),
  which is why the toolchain tracks one stable branch
- [Conventional Commits](https://www.conventionalcommits.org/), the commit
  message rules
- [semantic-release](https://semantic-release.gitbook.io/), the release tool

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for working on the toolchain itself:
the layout, testing a change, releases and which pins move by hand.

## License

This template is under the MIT License. See [LICENSE](LICENSE). Godot Engine
is MIT-licensed too, and games made with Godot must include
[Godot's licence text](https://godotengine.org/license).

Copyright Birdcall Studio
