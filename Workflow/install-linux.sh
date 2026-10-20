#!/usr/bin/env bash
# Builds a release and installs it for the current user:
#   ~/.local/opt/catussh            the bundle
#   ~/.local/bin/catussh            a link to it
#   ~/.local/share/applications     the desktop entry
#   ~/.local/share/icons/hicolor    the icon
# Uninstall with:  bash Workflow/install-linux.sh --uninstall
set -euo pipefail
cd "$(dirname "$0")/.."

prefix="${XDG_DATA_HOME:-$HOME/.local/share}"
opt="$HOME/.local/opt/catussh"
id=me.omicron0314.catussh

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -rf "$opt" "$HOME/.local/bin/catussh" "$prefix/applications/$id.desktop" "$prefix/icons/hicolor/256x256/apps/$id.png"
  echo "catussh removed (your servers stay in $prefix/$id)" >&2
  exit 0
fi

flutter build linux --release
rm -rf "$opt"
mkdir -p "$opt" "$HOME/.local/bin" "$prefix/applications" "$prefix/icons/hicolor/256x256/apps"
cp -r build/linux/x64/release/bundle/. "$opt/"
ln -sf "$opt/catussh" "$HOME/.local/bin/catussh"
install -m 644 linux/packaging/$id.desktop "$prefix/applications/$id.desktop"
install -m 644 linux/packaging/$id.png "$prefix/icons/hicolor/256x256/apps/$id.png"
command -v update-desktop-database >/dev/null && update-desktop-database "$prefix/applications" || true
echo "catussh installed to $opt" >&2
