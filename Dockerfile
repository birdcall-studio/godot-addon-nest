# syntax=docker/dockerfile:1
# The dev container and CI image: headless Godot and the lint and git hook
# tools. The Make targets and scripts stay in the checkout under toolchain/.
# .devcontainer/compose.yaml builds and runs it.
# x86-64 only: the tool downloads are x86-64 builds. Apple Silicon runs it
# under emulation.
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:3.0.12-ubuntu24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip zip xz-utils libfontconfig1 make \
    && rm -rf /var/lib/apt/lists/*

# Only what the install needs, so editing a Make target or a check script does
# not re-download Godot.
COPY toolchain/versions.sh /opt/nest/
COPY toolchain/bin/install-tools.sh toolchain/bin/nest-install-godot toolchain/bin/nest-fetch /opt/nest/bin/
RUN /opt/nest/bin/install-tools.sh

# Give the image's vscode user the host user's IDs, so files it writes in the
# mounted checkout belong to you. -o: CI runners' IDs may clash with a group.
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupmod -o -g "${USER_GID}" vscode \
    && usermod -o -u "${USER_UID}" -g "${USER_GID}" vscode \
    && chown -R vscode:vscode /home/vscode

# Docker Desktop shows the mounted checkout as owned by root, which git refuses
# to use. System-wide, because VS Code copies your own ~/.gitconfig into the
# container, which would replace a per-user setting.
RUN git config --system --add safe.directory /workspace

USER vscode
WORKDIR /workspace
