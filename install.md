# Agentic install — claude-account-switcher

You are an agent installing `claude-account-switcher` for the current user on macOS.
Follow these steps in order. After each step, check the expected outcome before
moving to the next. If a step fails, stop and report the exact error to the user.

This document is the source of truth for installation. Do not improvise.

---

## Step 1 — Prerequisite checks

Run these checks first. Abort with a clear message if any fail.

```bash
uname -s                                    # expect: Darwin
command -v git >/dev/null && echo "git ok"  # expect: git ok
command -v claude >/dev/null && echo "claude ok"  # expect: claude ok
command -v security >/dev/null && echo "security ok"  # expect: security ok
```

- If `uname -s` is not `Darwin`, abort: this tool is macOS only.
- If `claude` is missing, abort and tell the user to install Claude Code first
  (https://docs.claude.com/en/docs/claude-code/installation).
- `git` and `security` ship with macOS — they should always be present.

## Step 2 — Clone the repo

Default install location is `~/dev/claude-account-switcher`. If the user has a
preferred location, use that instead.

```bash
INSTALL_DIR="${INSTALL_DIR:-$HOME/dev/claude-account-switcher}"
mkdir -p "$(dirname "$INSTALL_DIR")"

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone https://github.com/CerratoA/claude-account-switcher.git "$INSTALL_DIR"
fi
```

Expected: the directory exists and contains `claude-acct`, `install.sh`, `README.md`.

## Step 3 — Run the installer

```bash
"$INSTALL_DIR/install.sh"
```

This symlinks `claude-acct` into `~/.local/bin/`. The installer prints either:

- `installed: /Users/<user>/.local/bin/claude-acct -> ...` — success.
- A `warning: ~/.local/bin is not on your PATH` notice — proceed to **Step 4**.

If the user prefers a different prefix (e.g. `/usr/local`), run instead:

```bash
PREFIX=/usr/local "$INSTALL_DIR/install.sh"   # may need sudo
```

## Step 4 — Ensure ~/.local/bin is on PATH

Only do this if Step 3 emitted the PATH warning.

Detect the user's shell:

```bash
basename "$SHELL"   # typically: zsh (default on macOS) or bash
```

Append to the appropriate rc file if not already present:

```bash
RC="$HOME/.zshrc"   # or ~/.bashrc for bash users
LINE='export PATH="$HOME/.local/bin:$PATH"'
grep -qxF "$LINE" "$RC" 2>/dev/null || printf '\n%s\n' "$LINE" >> "$RC"
```

Tell the user: "Open a new terminal or run `source ~/.zshrc` for the PATH
change to take effect."

## Step 5 — Verify the binary works

```bash
claude-acct help
```

Expected: a usage block starting with `claude-acct — switch between Claude Code
subscription accounts`.

If `claude-acct: command not found`, the PATH is not set up. Loop back to
Step 4, or invoke the binary by full path: `~/.local/bin/claude-acct help`.

## Step 6 — Save the user's first profile

This step requires a logged-in Claude Code session. Hand off to the user:

> Run `claude` and `/login` with the first account you want to manage. Tell me
> when you are back at the shell prompt and what name to give this profile
> (e.g. `personal`, `work`, `client-acme`).

When the user confirms and provides a name:

```bash
claude-acct add <name>
```

Expected output: `saved profile '<name>' (now active)`.

Repeat for additional accounts:

> In `claude`, run `/logout`, then `/login` as the next account. Tell me when
> ready and what name to give it.

```bash
claude-acct add <next-name>
```

## Step 7 — Verification

```bash
claude-acct list      # expect: every saved profile listed; '*' beside the active one
claude-acct current   # expect: the name of the most recently added profile
```

Confirm both outputs to the user.

## Step 8 — Optional: prompt integration

Offer this only if the user asks or confirms they want it. zsh only.

```bash
RC="$HOME/.zshrc"
LINE='PROMPT="%F{cyan}[\$(claude-acct current 2>/dev/null || echo none)]%f $PROMPT"'
grep -qF 'claude-acct current' "$RC" 2>/dev/null || printf '\n%s\n' "$LINE" >> "$RC"
```

Then: "Open a new terminal to see the active profile in your prompt."

## Done

Tell the user:

> Installed. Use `claude-acct switch <name>` to swap accounts. The previously
> active profile auto-saves before the swap, so token rotations don't strand
> you.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `error: no credential in keychain` on `add` | User isn't logged in | Run `claude` and `/login`, then re-run `claude-acct add` |
| `claude-acct: command not found` after install | `~/.local/bin` not on PATH | See Step 4, then open a new shell |
| `error: profile '<name>' not found` on `switch` | Typo or profile not saved | Run `claude-acct list` to see exact names |
| Switching seems to do nothing | `claude` was already running | Quit and relaunch `claude` after switching |
| `security: SecKeychainSearchCopyNext: The specified item could not be found` | Empty keychain entry — already cleared | Harmless; the next `add` will populate it |

## Notes for the agent

- This tool ONLY works with Claude Code subscription logins (OAuth credentials
  in macOS Keychain). It does NOT work with `ANTHROPIC_API_KEY` users.
- The script is idempotent: re-running `install.sh` is safe.
- Stored profile files (`~/.claude/keychain.<name>.txt`) contain plaintext
  OAuth tokens with `chmod 600`. Never print their contents to the user or to
  logs.
- Do not commit `~/.claude/` to a git repo. The shipped `.gitignore` defends
  the project repo itself but not the user's home directory.
