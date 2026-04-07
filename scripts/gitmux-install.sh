#!/usr/bin/env bash
set -euo pipefail

GITMUX_VERSION="v0.11.5"
INSTALL_DIR="${HOME}/.local/bin"
BINARY="${INSTALL_DIR}/gitmux"

if [[ -x "$BINARY" ]] && "$BINARY" -V 2>/dev/null | grep -q "${GITMUX_VERSION#v}"; then
  exit 0
fi

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
  darwin) OS="macOS" ;;
  linux)  OS="linux" ;;
  *)      echo "gitmux: unsupported OS: $OS" >&2; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  i386|i686)     ARCH="386" ;;
  *)             echo "gitmux: unsupported arch: $ARCH" >&2; exit 1 ;;
esac

TARBALL="gitmux_${GITMUX_VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/arl/gitmux/releases/download/${GITMUX_VERSION}/${TARBALL}"

mkdir -p "$INSTALL_DIR"

if command -v curl &>/dev/null; then
  curl -sL "$URL" | tar xz -C "$INSTALL_DIR" gitmux
elif command -v wget &>/dev/null; then
  wget -qO- "$URL" | tar xz -C "$INSTALL_DIR" gitmux
else
  echo "gitmux: curl or wget required" >&2
  exit 1
fi

chmod +x "$BINARY"
