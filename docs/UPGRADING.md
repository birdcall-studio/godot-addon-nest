# Upgrading

An add-on carries its own copy of the toolchain, from the
[godot-addon-nest](https://github.com/birdcall-studio/godot-addon-nest)
release named in `toolchain/VERSION`. It changes only when you upgrade it.

To move an add-on to a newer template release:

1. Read the template's GitHub release notes from your version to the new
   one, and the sections below for any release in between that needs a step.
2. In the add-on's dev container, run `make upgrade FROM=<tag>`, for example
   `make upgrade FROM=v2.1.1`. It clones the template at that tag and replaces
   the toolchain files listed in `CONTRIBUTING.md`. It does not touch the
   add-on's code, your `tests/test_*.gd` files, the README or `local.mk`.
3. If `toolchain/VERSION` said `main` or a release before v2.1.2, run the same
   `make upgrade` a second time. An older upgrade script copies only its own,
   older list of files. The second run uses the new script, so it also copies
   any files the template has added. From v2.1.2 on, the upgrade hands over
   to the new release's script, so one run is enough.
4. Review `git diff`. If the upgrade overwrote a change of your own, put it
   back. If it would help other add-ons, think about moving it into the
   template instead. The upgrade replaces the whole `toolchain/` folder. For
   other files, it copies the new version over the old one but never deletes
   anything, so a file the template has removed stays in your repo. The
   release notes say when to delete one. A stale workflow matters most,
   because it keeps running.
5. Rebuild the dev container, make any changes the sections below list, and
   run `make check`.
6. Commit with a message such as `chore: upgrade the toolchain to 2.1.1`.

If an upgrade from before v2.1.2 stops with a `cp` error, the template has
removed a file the old list still names. Clone the template at the tag into a
folder inside this repo, run that clone's `toolchain/bin/nest-upgrade <folder>`,
then delete the folder.

`FROM` can also be a path to a template checkout that the dev container can
see. The container sees only this repo's folder, so put the checkout inside
it, and delete it afterwards. Use this to try an unreleased change.

## Releases that need a step

### 2.3.0: a weekly pull request for Godot patches

The image now installs the exact Godot release in `GODOT_RELEASE`, and the
new Godot patch workflow opens a pull request for each new patch. In the
**Actions > General** settings for both the organisation and the repo, allow
GitHub Actions to create pull requests. Until you do, the workflow fails each
week.

## Major releases

A major release needs a change in the add-on's own files, such as a new Godot
branch. Each one gets a section here.

### 2.0.0: a release only adds a tag, after the checks pass

A release now runs only after Validate passes on `main`. It pushes only a
`vX.Y.Z` tag. It no longer commits `CHANGELOG.md` or the version in
`plugin.cfg` back to `main`. The release notes and the zip carry both.

- Move any Make targets of your own from the `Makefile` into a new
  `local.mk`. The upgrade has already replaced the `Makefile`; find them in
  `git diff`.
- Delete `CHANGELOG.md`, or keep it as a frozen record. Nothing writes it
  any more.
- Leave the `version=` line in `plugin.cfg` as it is.
- Upgrading from 1.x leaves `main` in `toolchain/VERSION`; replace it with
  the tag you upgraded to. Later upgrades write it themselves.
- If `main` is protected, require the **Check** and **Conventional commits**
  checks. The old **Doctor, lint, import and test** check no longer reports.
