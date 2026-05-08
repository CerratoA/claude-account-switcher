# claude-account-switcher

Switch between multiple **Claude Code** subscription accounts (Pro / Max) on
macOS without losing your shared `~/.claude` setup.

A 130-line bash script. No dependencies beyond the macOS `security` command
that already ships with the OS.

## Why this approach

Most community switchers isolate the entire `~/.claude` directory per account
by setting `CLAUDE_CONFIG_DIR`. That works, but it forces you to symlink your
skills, rules, hooks, MCP servers, and harness into every profile or maintain
duplicates.

`claude-account-switcher` only swaps the **OAuth credential** in the macOS
Keychain. Everything else in `~/.claude` — settings, skills, agents, hooks,
MCP servers, project history — stays shared across all accounts. One source
of truth.

| Concern | This tool | `CLAUDE_CONFIG_DIR`-based switchers |
|---------|-----------|--------------------------------------|
| Skills / rules / hooks per account | shared | must symlink or duplicate |
| Project history per account | shared | isolated |
| Setup complexity | one script | symlink trees / multiple dirs |
| Account isolation guarantees | credential only | full config |

If you actually want isolated history per account, use a `CLAUDE_CONFIG_DIR`
switcher instead — see [clausona](https://github.com/larcane97/clausona) or
[claude-swap](https://github.com/realiti4/claude-swap).

## Install

### One-line agentic install (recommended)

Paste this into Claude Code (or any agent with web access):

> Install claude-account-switcher by following https://github.com/CerratoA/claude-account-switcher/blob/main/install.md

The agent fetches [`install.md`](install.md), runs the prereq checks, clones
the repo, runs the installer, fixes your `PATH` if needed, and walks you
through saving your first profiles. End-to-end, no other context required.

### Manual install

```bash
git clone https://github.com/CerratoA/claude-account-switcher.git
cd claude-account-switcher
./install.sh
```

This symlinks `claude-acct` into `~/.local/bin`. Make sure that directory is
on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To install elsewhere:

```bash
PREFIX=/usr/local ./install.sh   # may need sudo
```

## Usage

```bash
# Log in to your first account, then save it
claude   # /login as account A
claude-acct add personal

# Log out, log in to the second account, save it too
claude   # /logout, /login as account B
claude-acct add work

# Switch between them
claude-acct switch personal
claude-acct switch work

# Inspect state
claude-acct list      # shows all profiles, marks active with '*'
claude-acct current   # prints active profile name

# Remove a profile
claude-acct remove old-client
```

Aliases: `switch`/`use`, `list`/`ls`, `current`/`active`/`whoami`,
`remove`/`rm`/`delete`.

### How `switch` stays fresh

OAuth tokens occasionally rotate. On every `switch`, the previously-active
profile's stored credential is **automatically refreshed** from the current
Keychain entry before the swap. This means you don't have to remember to
re-`add` after Claude rotates a token.

### Show active profile in your prompt

```bash
# zsh — add to ~/.zshrc
PROMPT='%F{cyan}[$(claude-acct current 2>/dev/null || echo none)]%f %~ %# '
```

## Files

| Path | Purpose |
|------|---------|
| `~/.claude/keychain.<name>.txt` | Stored OAuth credential per profile (`chmod 600`) |
| `~/.claude/active-profile` | Name of the currently active profile |

Override the storage directory with `CLAUDE_ACCT_STORE`.

## Security

Stored credential files contain **plaintext OAuth tokens**. They live in
`~/.claude` with `chmod 600` (owner read/write only).

**Recommended:**
- Keep FileVault enabled (it is by default on modern macOS).
- Don't sync `~/.claude` to cloud storage (Dropbox, iCloud, etc.).
- Don't commit `~/.claude` to a git repo. The included `.gitignore` defends
  against this in case you ever turn `~/.claude` into a repo.

This is a deliberate tradeoff: storing tokens at rest enables offline switching
and faster swaps, at the cost of weaker confidentiality than Keychain alone.
If that tradeoff is unacceptable for you, use `/logout` + `/login` instead.

## Requirements

- macOS (uses the `security` command for Keychain access)
- bash 3.2+ (the version shipped with macOS)
- A Claude subscription. Does not work with API keys.

## Uninstall

```bash
rm ~/.local/bin/claude-acct
rm ~/.claude/keychain.*.txt ~/.claude/active-profile
```

## License

MIT — see [LICENSE](LICENSE).
