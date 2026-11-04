# Tool versions for the dev container image and the release workflow.
# Environment variables override them.
# Dependabot can't read this file. CONTRIBUTING.md lists how each pin gets
# updated.
#
# toolchain/VERSION is different: it names the template release a project
# was made from. It says main until the first release.

# GODOT_VERSION is the Godot stable branch (major.minor) we build and test on.
# GODOT_RELEASE is the patch release the image installs. Godot supports only
# the newest patch of a branch, so the Godot patch workflow opens a pull
# request for each new one:
# https://docs.godotengine.org/en/stable/about/release_policy.html
: "${GODOT_VERSION:=4.7}"
: "${GODOT_RELEASE:=4.7.2}"

: "${EC_VERSION:=v4.0.2}"
: "${LEFTHOOK_VERSION:=2.2.2}"
: "${NODE_VERSION:=24.22.2}"
: "${MARKDOWNLINT_VERSION:=0.24.0}"
: "${SHELLCHECK_VERSION:=v0.11.0}"
# ShellCheck has no checksum file, so this is the SHA-256 of its
# linux.x86_64.tar.xz.
: "${SHELLCHECK_SHA256:=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198}"
: "${ACTIONLINT_VERSION:=1.7.12}"

# semantic-release, its exec plugin and the Conventional Commits preset, for
# the Release workflow. Keep the preset on the major version that
# @semantic-release/release-notes-generator tests against.
: "${SEMANTIC_RELEASE_VERSION:=25.0.9}"
: "${SR_EXEC_VERSION:=7.1.0}"
: "${SR_CONVENTIONALCOMMITS_VERSION:=9.3.1}"
