# .dotfiles

My personal cross-platform config - WezTerm, zsh, tmux, Starship, Git, VS Code. Same setup on macOS, Linux, and WSL.

## Install

### Prereqs

`dot init` bootstraps everything else (Homebrew on macOS, apt-installed tools on Linux/WSL, plus a handful of curl-installed binaries). It needs three things on PATH before it can run:

- **`bash`** - to execute the script
- **`git`** - to clone this repo and a couple of helpers (antidote, etc.)
- **`curl`** - used by the Homebrew installer, starship, zoxide, eza, gh, nvm

What you do *not* need: a preinstalled package manager. On macOS the script installs Homebrew if it's missing. On Debian/Ubuntu/WSL `apt-get` is always present. On other Linux distros (Fedora, Arch, etc.) the script will warn and you'll need to install the package list by hand.

Quick way to get the meta-prereqs:

| Platform | Command |
|---|---|
| macOS | `xcode-select --install` (ships git + curl) |
| Debian/Ubuntu/WSL | `sudo apt-get update && sudo apt-get install -y git curl` |

### Run it

Clone to `~/.dotfiles`. (GNU Stow's default target is the repo's *parent* directory, so cloning to `~/.dotfiles` makes symlinks land in `$HOME` with no extra flags.)

```sh
git clone https://github.com/jmsgrn/.dotfiles ~/.dotfiles
cd ~/.dotfiles
./dot init
```

You can clone elsewhere, but then pre-export `DOTFILES` and Stow needs an explicit `--target $HOME` (which `dot link` always passes anyway).

`dot init` detects the OS, installs everything in the package manifest (`bin/packages/*.txt`), then symlinks all configs with GNU Stow. Existing config is tarballed to `~/.dotfiles-backup/dotfiles_backup_<timestamp>.tar.gz` first. Safe to re-run.

### Claude Code skills

Global skills live in their own repo (`~/projects/skills`) rather than in this one, so
they can be published separately. `dot init` wires them up, or run it on its own:

```sh
dot skills
```

That clones the skills repo if it's missing and symlinks `~/.claude/skills` to it.
If that path is already a real directory holding machine-local skills, it is moved to
`~/.claude/skills.local-<timestamp>` first - nothing is deleted, but you'll need to
merge anything you want to keep into the repo by hand.

Point it somewhere else with `SKILLS_REPO=<url> dot skills`.

Project-specific skills are not managed here. They belong in their own repo under
`<repo>/.claude/skills/` and arrive when you clone it.

### After install: log out and back in

`dot init` switches your login shell to zsh via `usermod`, but `$SHELL` in your current desktop session was set at login and won't update until you log out and back in (or reboot). Until then, new terminals will still inherit `$SHELL=/bin/bash` even though they actually run zsh.

The check that matters is:

```sh
getent passwd "$USER" | cut -d: -f7   # should print /bin/zsh
```

If that prints zsh, the install succeeded. `$SHELL` will catch up after your next desktop login.

## The `dot` CLI

`dot` is a small cross-platform package + dotfiles manager (on `$PATH` via `$DOTFILES/bin`):

| Command | What it does |
|---|---|
| `dot init` | full bootstrap: install the package manifest, link configs, set up shell |
| `dot add <pkg>` | install `<pkg>` and add it to the manifest (`bin/packages/*.txt`) |
| `dot remove <pkg>` | uninstall `<pkg>` and drop it from the manifest |
| `dot update` | upgrade packages + `git pull` + relink |
| `dot list` | show the package manifest with install status |
| `dot link [-f]` | stow `home/` into `$HOME` (`-f`/`--force` replaces conflicts) |
| `dot unlink` | remove our symlinks (`stow -D`) |
| `dot backup` | tar files stow would conflict with into `~/.dotfiles-backup/` |
| `dot clean` | remove broken symlinks pointing into `$DOTFILES` |
| `dot doctor` | health check (prereqs, symlinks, missing packages) |

**Packages** live as plain one-per-line files in `bin/packages/` (`brew.txt`, `brew-cask.txt`, `apt.txt`, `curl.txt`); `dot add`/`remove` edit them. **Configs**: drop a file under `home/` mirroring its place in `$HOME` (e.g. `home/.config/foo/` → `~/.config/foo/`), then `dot link` - Stow folds directories automatically.

### Examples

```sh
# bootstrap a fresh machine: install packages, link configs, set up zsh
./dot init

# add a tool — installs it now AND records it in the manifest for next time
dot add ripgrep          # OS package (apt on Linux, brew on macOS)
dot add pi               # custom installer (bun/npm) — routed automatically

# what's tracked, and is it installed here?
dot list

# upgrade packages, git pull the repo, then relink
dot update

# relink after editing the home/ tree (idempotent; safe to re-run)
dot link

# health check: prereqs, every tracked file's symlink, missing packages
dot doctor

# drop a tool from the manifest (uninstalls it where possible)
dot remove ripgrep
```

## What's inside

- **WezTerm** - cross-platform GPU terminal, single Lua config
- **zsh + antidote** - fast plugin loading, OMZ plugins without the framework. Config lives under `$XDG_CONFIG_HOME/zsh/` via `ZDOTDIR`; the only thing in `$HOME` is `~/.zshenv`, which sets `ZDOTDIR` and sources the env file there.
- **Starship** - cross-shell prompt
- **tmux** - persistent sessions with vim-style splits and the Primeagen `tmux-sessionizer`. Config at `$XDG_CONFIG_HOME/tmux/tmux.conf` (tmux 3.1+).
- **Modern CLI tools** - `zoxide` (smart cd), `fzf` (fuzzy finder), `bat` (cat with colors), `eza` (modern ls), `fd` (modern find), `ripgrep`
- **Git** - sensible defaults at `$XDG_CONFIG_HOME/git/config`, global gitignore at `$XDG_CONFIG_HOME/git/ignore`. Identity is kept in untracked `~/.config/git/config.local` (created by `dot init`).
- **VS Code** - settings, keybindings, and an `extensions.txt` that gets auto-installed
- **Claude Code** - `settings.json` (model, effort, theme) plus a two-line `statusline.sh`: model · git branch · dir · context meter, and your most recent prompt underneath. Only those two files are tracked under `home/.claude/`; credentials, transcripts, and plugin state stay in the untracked `~/.claude` — you just `claude` log in per machine.

## Layout

GNU Stow mirrors everything under `home/` into `$HOME` (folding directories as needed):

```
.dotfiles/
├── dot                       # entry point (symlink → bin/dot)
├── README.md
├── LICENSE
├── bin/
│   ├── dot                   # the package + dotfiles manager (GNU Stow under the hood)
│   ├── lib/
│   │   ├── packages.sh       # reads the package manifest into arrays
│   │   └── bootstrap.sh      # OS detect, installers, fonts, shell setup (init/update)
│   ├── packages/             # the manifest — one package per line
│   │   ├── brew.txt          # macOS: brew install
│   │   ├── brew-cask.txt     # macOS: brew install --cask
│   │   ├── apt.txt           # Linux/WSL: apt-get install
│   │   └── curl.txt          # custom installers (starship, eza, nvm, pi, …)
│   └── tmux-sessionizer
├── assets/                   # fonts + wallpapers (installed by `dot init`, not stowed)
└── home/                     # the Stow package — mirrors $HOME
    ├── .zshenv               # sets ZDOTDIR, then sources $ZDOTDIR/.zshenv
    ├── .claude/              # settings.json + statusline.sh (creds/transcripts stay untracked)
    └── .config/
        ├── zsh/              # .zshenv (env/PATH), .zshrc, .zsh_plugins.txt, aliases/functions/exports/tools.zsh
        ├── git/             # config, ignore (identity in untracked config.local)
        ├── tmux/            # tmux.conf
        ├── wezterm/         # wezterm.lua
        ├── starship/        # starship.toml (STARSHIP_CONFIG points here)
        └── Code/User/       # settings.json, keybindings.json, extensions.txt
```

`dot link` (i.e. `stow home`) symlinks `home/.config/zsh` → `~/.config/zsh`, `home/.zshenv` → `~/.zshenv`, and so on. On macOS, VS Code config is *additionally* linked into `~/Library/Application Support/Code/User/` by `dot init`, since Stow only covers `~/.config`.

## Shortcuts and aliases I actually use

### fzf - in any zsh session

| Key | Action |
|---|---|
| `Ctrl-T` | fuzzy file search at the cursor (with `bat` preview) |
| `Ctrl-R` | fuzzy history search |
| `Alt-C` | fuzzy `cd` into a directory (with `eza --tree` preview) |
| `**` + Tab | trigger fuzzy completion for any command |

### zoxide - smart cd

| Command | Action |
|---|---|
| `z foo` | jump to the most-visited dir matching "foo" |
| `z foo bar` | jump to the dir matching both |
| `zi` | interactive selection from your zoxide history |

### History substring search

Start typing a command then press `Up` / `Down` - filters history to commands that begin with what you've typed.

### Modern CLI aliases

| Alias | Runs |
|---|---|
| `ls` / `ll` / `la` / `tree` | `eza` with icons, git status, group dirs first |
| `cat <file>` | `bat` with syntax highlighting |
| `fd <pat>` | works whether the binary is `fd` or `fdfind` (Ubuntu) |
| `man <cmd>` | uses `bat` as the pager - colored, syntax-highlighted man pages |

### tmux (prefix = `Ctrl-Space`)

| Key | Action |
|---|---|
| `prefix` `\|` | split pane vertically (keeps current dir) |
| `prefix` `-` | split pane horizontally (keeps current dir) |
| `prefix` `c` | new window |
| `prefix` `d` | detach (session keeps running) |
| `prefix` `h/j/k/l` | navigate panes vim-style |
| `prefix` `H/J/K/L` | resize panes (hold and repeat) |
| `prefix` `r` | reload `.tmux.conf` |
| `prefix` `[` | enter copy mode (vim keys: `v` select, `y` yank) |
| `tmux a` | attach to last session |
| `tmux ls` | list sessions |

### tmux-sessionizer (Primeagen pattern)

Fuzzy-find a project directory and either create-or-attach a tmux session named after it. Bound to a global key.

```sh
bindkey -s '^f' '^utmux-sessionizer\n'   # Ctrl-f
```

### zsh aliases

| Alias | Expands to |
|---|---|
| `ll` | `ls -lAh` |
| `..` / `...` / `....` | `cd ..` (one/two/three up) |
| `gs` | `git status` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `gcm "msg"` | `git commit -m "msg"` |
| `gcam "msg"` | `git add -A && git commit -m "msg"` (function) |
| `gp` / `gpu` | `git pull` / `git push` |
| `gl` | `git log --oneline --graph --decorate -20` |
| `gco` / `gsw` / `gb` | `git checkout` / `git switch` / `git branch` |
| `reload` | `source ~/.zshrc` |
| `path` | print `$PATH` one entry per line |
| `mkcd <dir>` | mkdir + cd in one shot |
| `extract <file>` | extract any common archive |

### VS Code

| Key | Action |
|---|---|
| `Ctrl-P` | quick file open |
| `Ctrl-Shift-P` | command palette |
| `` Ctrl-` `` | toggle integrated terminal |
| `Ctrl-Shift-E` | reveal in explorer |

### WezTerm (Mac: `Cmd`, Linux/WSL: `Ctrl-Shift`)

| Key | Action |
|---|---|
| `mod-t` | new tab |
| `mod-w` | close tab |
| `mod-[ / mod-]` | prev / next tab |
| `mod-d` | split pane vertically |
| `mod-shift-d` | split pane horizontally |

## Per-machine overrides (not tracked)

These files get sourced if present, ignored if missing - your secrets / work identity / box-specific tweaks live here:

| File | What it's for |
|---|---|
| `~/.config/git/config.local` | git user.name / user.email (created by `dot init`) |
| `~/.config/zsh/work.zsh` | work-only aliases/paths/env (drop a real file here on the work box) |
| `~/.config/zsh/*.local.zsh` | any per-machine zsh you want sourced |

The `.zshrc` glob `$ZDOTDIR/*.zsh` (== `~/.config/zsh/*.zsh`) picks them all up automatically.

## License

MIT
