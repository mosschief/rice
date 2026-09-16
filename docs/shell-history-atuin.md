# Better shell history search (atuin)

Replaces `Ctrl+R` reverse-search with a fuzzy, full-text search over every
command you have ever run, stored in a local SQLite database. It also filters by
the directory a command was run in — the "search this project only vs. search
everything" toggle — and keeps unlimited history, so the small `HISTSIZE` that
otherwise clobbers old commands stops mattering.

[atuin](https://github.com/atuinsh/atuin) is the tool. The lighter alternative
is `fzf` (fuzzy `Ctrl+R` only, no database, no per-directory filter); atuin is
the more capable option and subsumes both `fzf`'s history search and the
zsh-only `per-directory-history` plugin.

Sync is **off** below — history stays on this machine, no account. Turn it on
later with `atuin register` / `atuin login` if you ever want it across machines.

## Install

atuin is in the Arch repos:

```
sudo pacman -S atuin
```

Then wire it into the shell. This setup uses `bash` by default (foot launches a
login shell); do the bash block. The zsh block is here for a zsh machine.

**bash** — atuin needs `bash-preexec` to hook commands. `atuin init` prints the
glue; append it to `~/.bashrc`:

```
echo 'eval "$(atuin init bash)"' >> ~/.bashrc
```

If `Ctrl+R` does nothing after reloading, install `bash-preexec` (atuin bundles
it in recent versions, but older ones expect it present):

```
sudo pacman -S bash-preexec    # or: source it from ~/.bash-preexec.sh
```

**zsh**:

```
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
```

Import the history you already have, once:

```
atuin import auto
```

Reload the shell (`exec bash`) or open a new foot window. `Ctrl+R` now opens
atuin.

## Using it

- **`Ctrl+R`** — open the search. Type any part of the command; it fuzzy-matches
  across the whole history.
- **`Ctrl+R` again, inside the search** — cycle the filter mode:
  **global → host → session → directory**. **directory** mode is the
  per-directory history: only commands previously run in the current folder.
- **Enter** runs the selection; **Tab** puts it on the prompt without running.
- **Up arrow** is also taken over by atuin. To keep the plain bash up-arrow,
  change the init line to `eval "$(atuin init bash --disable-up-arrow)"`.

## History size

atuin keeps everything in its database, so its own history is effectively
unlimited. Bash's *native* history is still worth enlarging as a fallback and to
give `atuin import auto` a deeper baseline — the stock `HISTSIZE=1000` /
`HISTFILESIZE=2000` throws away all but the last couple thousand commands
([why](https://stackoverflow.com/questions/9457233/unlimited-bash-history)).
In `~/.bashrc`:

```
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT="%F %T "     # timestamp each entry
shopt -s histappend         # append across sessions instead of overwriting
```

(`HISTSIZE=-1` / `HISTFILESIZE=-1` makes native history unlimited too, but a
large finite cap keeps the file from growing without bound.)

## Config

atuin's own config is `~/.config/atuin/config.toml`. Useful knobs:

```toml
# default filter when the search opens: global | host | session | directory
filter_mode = "global"
# or make it directory-aware only when a shell key (up) opens it:
filter_mode_shell_up_key_binding = "directory"
search_mode = "fuzzy"       # fuzzy | prefix | fulltext
style = "compact"           # compact | full
```

Not tracked in this repo — atuin writes it on first run and it holds no
machine-specific paths worth checking in.
