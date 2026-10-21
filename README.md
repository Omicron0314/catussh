# catussh

**English** · [简体中文](./README.zh-Hans.md)

An SSH client for the Linux and macOS servers you look after, rebuilt in Flutter with
Material You: an SSH terminal, SFTP file transfer with a text editor, and a live
resource monitor, side by side for every server. Linux desktop first; Android next.
English and Simplified Chinese, following the system language.

[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./Resources/Screenshots/home-dark.webp">
  <img alt="catussh's Home page: Quick Connect at the top and a grid of saved servers, each with Connect, Files and Monitor buttons." src="./Resources/Screenshots/home-light.webp">
</picture>

This is a fork of [mizorewww/catussh](https://github.com/mizorewww/catussh), the native
macOS app, rewritten so it runs where SwiftUI and Ghostty's embedding API do not.

## Install (Linux)

Needs Flutter 3.47+, `clang cmake ninja pkgconf gtk3 libsecret` and a Secret Service
keyring (GNOME Keyring or KWallet).

```sh
git clone https://github.com/Omicron0314/catussh.git
cd catussh
bash Workflow/install-linux.sh        # release build into ~/.local/opt/catussh
```

`bash Workflow/install-linux.sh --uninstall` removes it again.

## Features

- **Terminal, Files, Editor and Monitor for every server**, one click each, with a
  switcher in every session's toolbar and one sidebar row per server with something open.
- **Quick Connect**: type `user@host`, `user@host:2222` or a full `ssh` command and press
  Enter; recent commands are suggested (Ctrl+Enter).
- **Server monitor** for Linux and macOS: CPU (per core), memory, swap, disks, network and
  NVIDIA GPUs, with no agent to install.
- **Identities** (passwords or keys) shared across servers, **snippets** run on many
  servers at once, **port forwarding** (local and remote) and **tray cats**: a running cat
  per server in the system tray whose speed follows its CPU.
- **Host keys are checked**: a server's key is saved on first connection and a changed
  key is refused.
- Servers, identities and snippets are stored encrypted (AES-256-GCM); the key lives in
  the system keyring.
- **Material You**: colors come from the desktop accent (or a seed color you pick), light,
  dark or system; the window's own title bar (drag, minimize, maximize, close) is drawn in
  those colors instead of the system's.
- **English and 简体中文**: the interface follows the system language; Settings › General ›
  Language changes it. Dates and relative times follow too; server names, paths and
  terminal output are left as they are.

## Screenshots

| | |
|---|---|
| ![Servers](./Resources/Screenshots/servers-light.webp) | ![Monitor](./Resources/Screenshots/monitor-dark.webp) |
| ![Terminal](./Resources/Screenshots/terminal-dark.webp) | ![Files](./Resources/Screenshots/files-light.webp) |
| ![Identities](./Resources/Screenshots/identities-light.webp) | ![Terminal settings](./Resources/Screenshots/settings-dark.webp) |
| ![Home in Chinese](./Resources/Screenshots/home-light-zh.webp) | ![Settings in Chinese](./Resources/Screenshots/settings-dark-zh.webp) |

## Keyboard

| | |
|---|---|
| New server | Ctrl+Shift+N |
| Settings | Ctrl+, |
| Show or hide the sidebar | Ctrl+\\ |
| New terminal on this server / close it | Ctrl+Shift+T / Ctrl+Shift+W |
| Terminal text size | Ctrl+= / Ctrl+- |
| Copy / paste in a terminal | Ctrl+Shift+C / Ctrl+V |
| Files: up, go to folder, reload | Alt+Up, Ctrl+Shift+G, Ctrl+R |
| Editor: save, open, close file | Ctrl+S, Ctrl+O, Ctrl+W |

## Development

```sh
flutter test                                   # unit tests (parsers, store, known hosts…)
flutter run -d linux
```

Against a real server (a throwaway user-level sshd works):

```sh
CATUSSH_TEST_SSHD="127.0.0.1:2222:$USER:/path/to/key" flutter test test/ssh_integration_test.dart
CATUSSH_SHOTS=/tmp/shots flutter test test/tool/screenshots_test.dart   # renders the screenshots
```

`CATUSSH_DATA_DIR=/tmp/profile` runs the app on a separate profile whose key is kept in a
file (never use it for real data); `CATUSSH_OPEN=monitor:<server name>` opens a server's
tool at launch. The screenshots are rendered by `test/tool/screenshots_test.dart` with
`CATUSSH_SHOTS` (it needs `python3` with `fontTools` to take a CJK face out of the system
Noto collection).

The window is undecorated on purpose: `linux/runner/my_application.cc` turns the GTK title
bar off and `lib/features/shell/title_bar.dart` draws the drag area and the three window
buttons. On a tiling compositor the window is sized by the layout; when floating, resize
it with the compositor's own mouse bindings.

Layout: `lib/core` (models, store, vault, known hosts, `ssh` command parser),
`lib/ssh` (connecting and signing in), `lib/monitor` (the monitor script and parsers),
`lib/sessions` (terminal, SFTP, editor, monitor, port forward, batch run),
`lib/app/router.dart` (navigation and open sessions), `lib/features/*` (the pages).

## License

MIT. Based on catussh by mizorewww, the continuation of Rayon by Lakr Aream.
