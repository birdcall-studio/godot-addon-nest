#!/usr/bin/env bash
# Install Godot and the lint and git hook tools.
# Run once while building the dev container image.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../versions.sh disable=SC1091
source "$here/../versions.sh"
bin="${PREFIX:-/usr/local}/bin"
mkdir -p "$bin"

"$here/nest-install-godot" "$GODOT_RELEASE"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh="https://github.com"

# The binary sits at the top of the archive (checked for v4.0.2).
rel="$gh/editorconfig-checker/editorconfig-checker/releases/download/${EC_VERSION}"
"$here/nest-fetch" "$rel/editorconfig-checker-linux-amd64.tar.gz" "$tmp/ec.tar.gz" \
    "$rel/checksums.txt"
tar -xzf "$tmp/ec.tar.gz" -C "$tmp"
install -m 0755 "$tmp/editorconfig-checker" "$bin/editorconfig-checker"

rel="$gh/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}"
"$here/nest-fetch" "$rel/lefthook_${LEFTHOOK_VERSION}_Linux_x86_64" "$tmp/lefthook" \
    "$rel/lefthook_checksums.txt"
install -m 0755 "$tmp/lefthook" "$bin/lefthook"

# ShellCheck publishes no checksum file, so versions.sh pins its hash.
"$here/nest-fetch" \
    "$gh/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    "$tmp/shellcheck.tar.xz" "sha256:${SHELLCHECK_SHA256}"
tar -xJf "$tmp/shellcheck.tar.xz" -C "$tmp"
install -m 0755 "$tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" "$bin/shellcheck"

rel="$gh/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}"
"$here/nest-fetch" "$rel/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" "$tmp/actionlint.tar.gz" \
    "$rel/actionlint_${ACTIONLINT_VERSION}_checksums.txt"
tar -xzf "$tmp/actionlint.tar.gz" -C "$tmp" actionlint
install -m 0755 "$tmp/actionlint" "$bin/actionlint"

# markdownlint-cli2 lints the Markdown files and needs Node.js.
node="node-v${NODE_VERSION}-linux-x64"
rel="https://nodejs.org/dist/v$NODE_VERSION"
"$here/nest-fetch" "$rel/$node.tar.xz" "$tmp/node.tar.xz" "$rel/SHASUMS256.txt"
mkdir -p /opt/node
tar -xJf "$tmp/node.tar.xz" -C /opt/node --strip-components=1
ln -sf /opt/node/bin/node /opt/node/bin/npm "$bin/"
/opt/node/bin/npm install --global --no-fund --no-audit "markdownlint-cli2@${MARKDOWNLINT_VERSION}"
ln -sf /opt/node/bin/markdownlint-cli2 "$bin/markdownlint-cli2"
