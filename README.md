<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/7/75/Z_Shell_Logo_Color_Vertical.svg" alt="Zsh Logo" width="150">
</p>

<div align = "center">

<h1><a href="https://github.com/adityastomar67/zsh-conf">Zsh-Conf</a></h1>
</div>

> **Blazing Fast, Modular, and Aesthetic Zsh Configuration Framework.** <br> A shell config with ~20ms load times. (Tested on M4)

This configuration is designed for speed, modularity, and a beautiful terminal experience. It leverages modern tools like `zoxide`, `fzf`, `eza`, and `starship` to provide a powerful command-line environment without the bloat.

---

## ✨ Key Features

- **🚀 Blazing Fast Startup**: Optimized with lazy-loading and bytecode compilation. Includes a built-in benchmark tool (`ZSH_BENCHMARK`).
- **🧩 Modular Architecture**: Clean separation between core logic, plugins, and user-specific config.
- **🔌 Plugin Management**: Done by own core module.
- **🎨 Visual Excellence**:
    - Integrated **Starship** prompt support.
    - Syntax Highlighting & Auto-suggestions.
    - "Fancy Startup" with ASCII art and motivational quotes.
    - Popular "Faaaah" sounds on wrong command inputs.
- **🛠️ Developer Ready**:
    - Pre-configured for **Git**, **Go**, **Python**, **Node**, etc.
    - **Tmux** auto-launch integration.
    - **Neovim** profile switcher (LazyVim, NvChad, AstroNvim, etc.).
- **🔒 Secure**: Environment variables and API keys are loaded safely from `.env`.

---

## 📦 Installation

To install, simply run the installation script:

```zsh
# Change directory to /tmp to avoid cluttering the home folder
cd /tmp

# Download the zsh configuration installer from the GitHub repository
#   -L: ensures we follow links
#   -o: specifies the output filename
curl -Lo \
    install.zsh \
    https://raw.githubusercontent.com/adityastomar67/zsh-conf/refs/heads/remastered/install.zsh

# Grant execute permissions to the downloaded script
chmod +x install.zsh

# Run the installer
command zsh install.zsh
```

### Protocol

The installation script executes a comprehensive setup flow:

1.  **Environment Detection**: Identifies your operating system (macOS/Linux) and active package managers (Homebrew, APT, Pacman).
2.  **Automated Provisioning**: Prompts to install missing dependencies using the most appropriate tool for your system.
3.  **Atomic Backups**: Automatically creates timestamped backups of your existing `.zshrc`, `.zshenv`, and other shell configurations to prevent data loss.
4.  **Core Installation**: Clones the framework into `~/.config/zsh-conf` and establishes the modular directory structure.
5.  **Configuration Linking**: Generates symlinks for entry points and initializes a local `.env` file for private environment variables.
6.  **Performance Optimization**: Compiles shell scripts into bytecode (`.zwc`) to guarantee the ~20ms startup time from the very first launch.

<br>

**Dependency Detection Details**

- The installer detects tools already present via **PATH**, **Volta**, **NVM**, or the OS package manager.
- For tools with different binary names (e.g., `ripgrep` → `rg`, `git-delta` → `delta`), the installer checks the correct binary.
- On macOS, if Homebrew is missing, dependency installation is skipped with a clear message so you can install via your preferred manager.

### Prerequisites

- **Nerd Font**: Required for icons in the prompt and `lsd`/`eza`. (e.g., [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)).

---

## ⚙️ Configuration

Start customizing by editing `~/.config/zsh-conf/user.conf`. This method is safe from git updates!<br>
Or you can just run the `zsettings` command to know all the availabe customisable options and edit from right there.

### 1. The `user.conf` File

This is your control center. Tweak flags to enable/disable features:

```bash
# ~/.config/zsh-conf/user.conf

# ---------------- Features ---------------- #
export ENABLE_AUTO_TMUX="No"        # Auto-start Tmux?
export LOAD_CUSTOM_ALIASES="Yes"    # Load alias shortcuts?
export ENABLE_FANCY_STARTUP="No"    # Show cool banner? Faah Sound?
export ZSH_BENCHMARK="Yes"          # Measure startup time?

# ---------------- Visuals ----------------- #
export PROMPT_THEME="gh0st"         # Choose your prompt!
export ENABLE_THEME_SH_INTEGRATION="No"

# ---------------- Performance ------------- #
export ENABLE_MINIMAL_MODE="No"     # "Yes" for root/slow machines
```

### 2. User Overrides

For custom aliases, functions, or exports that you don't want tracked by git (or are specific to _this_ machine), use:

- **File**: `~/User-Overrides.zsh`
- **Usage**: Automatically sourced at the end of `.zshrc`.
    - During installation, any `PATH` exports found in your existing `~/.zshrc` are copied into this file (once), so your custom paths are preserved.

### 3. Secrets (API Keys)

Store sensitive data in `.env` inside `~/.config/zsh-conf/`:

```bash
# ~/.config/zsh-conf/.env
export GITHUB_TOKEN="ghp_xxxx..."
export OPENAI_API_KEY="sk-xxxx..."
```

---

## 📂 Project Structure

```text
~/.config/zsh-conf/
├── .zshrc           # Main entry point (DO NOT EDIT)
├── user.conf        # User configuration flags & paths
├── install.zsh      # Installer script
├── lib/             # Core functions and utilities
├── plugins/         # Plugin definitions
└── zsh/             # Zsh internals
```

---

## 💡 Tips & Tricks

- **Benchmark**: See how fast your shell loads with the built-in timer (needs `ZSH_BENCHMARK="Yes"`).
- **Update**: Pull the latest changes from the repo by running `dotup -z` (it handles backups safely).
- **Mini Mode**: Set `ENABLE_MINIMAL_MODE="Yes"` in `user.conf` for a lightweight, dependency-free shell on servers.
  - **Excludes**: Plugin manager, heavy plugins (autosuggestions, syntax highlighting), Starship prompt, custom functions (`pj`, `lg`, `weather`), benchmarking tools, and the fancy startup sequence.
  - **Retains**: Basic aliases, history management, basic completions, Vi-mode keybindings, and optional Tmux auto-start.

---

## 🚀 Deep Dive: Custom Functions

This config isn't just about aliases; it packs powerful functions to speed up your workflow.

### 1. `pj` (Project Jumper)

Stop `cd`-ing into oblivion. `pj` uses `fzf` to fuzzy-find directories in your `~/Code`, `~/Projects`, or `~/Work` folders and jumps straight there.

- **Usage**: `pj` (interactive) or `pj react` (query).
- **Tech**: Powered by `fd` for speed and `fzf` for selection. It even integrates with `zoxide` to learn your habits.

### 2. `lg` (Lazygit Wrapper)

When you exit `lazygit`, you usually stay in the same directory you started in. `lg` fixes this.

- If you change directories inside Lazygit, `lg` will `cd` you to that directory upon exit.
- Keeps your shell context synced with your git context.

### 3. `weather`

Fetches a beautiful weather report from `wttr.in`.

- **Smart**: Automatically adjusts the format based on your terminal window size (full report on large screens, one-liner on phones).
- **Usage**: `weather` (defaults to your location) or `weather London`.

### 4. `kubectl` Guardrails

Ever deleted a production pod by mistake? Never again.

- Wraps `kubectl` to check your current context.
- If the context contains `prod`, `production`, or `live`, it **prompts for confirmation** before running destructive commands (`delete`, `apply`, `scale`).

---

## ⚡ Supercharged Aliases

We map short commands to their modern, faster equivalents.

### Navigation

| Alias        | Command         | Description                        |
| :----------- | :-------------- | :--------------------------------- |
| `..`         | `cd ..`         | Go up one level                    |
| `...`        | `cd ../..`      | Go up two levels                   |
| `.1` to `.9` | `cd -1`...      | Jump back in directory stack       |
| `-pj`        | `cd ~/Projects` | Dynamic bookmark (see `user.conf`) |

### Named Directories (Hashes)

Any shortcut defined in `user.conf` also becomes a global named directory.

- **`~pj`** -> Expands to `~/Projects`
- **`cd ~pj/project-name`** -> Works instantly.
- **`cp file.txt ~pj/`** -> Works instantly.
- **Prompt Shortening**: The prompt will even display `~pj` instead of the full path.

### Modern Replacements

| Alias  | Original | Replacement   | Why?                                     |
| :----- | :------- | :------------ | :--------------------------------------- |
| `cat`  | `cat`    | **`bat`**     | Syntax highlighting & git integration    |
| `ls`   | `ls`     | **`eza`**     | Icons, git status, better formatting     |
| `grep` | `grep`   | **`ripgrep`** | 10x faster searching                     |
| `find` | `find`   | **`fd`**      | Simple syntax, ignores git files         |
| `diff` | `diff`   | **`delta`**   | Side-by-side diffs with syntax highlight |

### Global Aliases (Pipes)

Use these _anywhere_ in a command.

- **`:G`** -> `| grep` (e.g., `ps aux :G python`)
- **`:L`** -> `| less` (e.g., `cat huge_file.log :L`)
- **`:NE`** -> `2> /dev/null` (Silence errors)

### Suffix Aliases

Just type the file name to open it!

- `main.py` -> Runs `python main.py`
- `README.md` -> Opens in `$EDITOR`
- `image.png` -> Opens in system image viewer
- `archive.zip` -> Lists contents

### The "Magic" Fixer

- **`please`**: Forgot `sudo`? Type `please`, and it re-runs the last command with sudo.
- **`Alt+s`**: Or maybe you're in buffer and want to add sudo to the command? just press `Alt+S`, and sudo will be added to the command.

### Contextual History Search

- **`up arrow`**: Search through your history if you have something in your buffer. or shows the last command.

---

## 🧠 Core Utilities & Lazy Loading

### Plugin Manager: `plug`

A custom, lightweight (<100 lines) plugin manager built right into `_core.utils`.

- **Fast**: Clones repos in parallel.
- **Lazy**: Supports the `defer` keyword to load plugins only when the shell is idle, slashing startup time.

### Eval Cache

Tools like `starship`, `zoxide`, and `rbenv` need to run `init` commands that can take 100ms+.

- **Solution**: We cache the output of these commands to a file.
- **Result**: Subsequent shells load instantly. The cache auto-refreshes if the binary changes.

### Lazy Loading Wrappers

We don't load heavyweight tools like `nvm` (Node) or `pyenv` (Python) until you actually use them.

- `nvm` is only loaded when you type `node`, `npm`, or `yarn`.
- Saves huge amounts of startup time.

### UI Enhanced Git commands

Custom wrappers that turn standard `git` output into a rich, visual experience.

- **`git clone`**: Adds visual headers, icons, and real-time stream coloring for a cleaner progress view.
- **`git pull`**: Displays local/remote branch context before syncing, with colorized status updates.
- **`git status`**: A complete overhaul using `awk` to provide an iconic, high-density overview of your workspace (Added `+`, Modified `M`, Deleted `D`, Conflicts `C`).
- **`git log`**: An interactive TUI powered by `fzf`.
    - **Preview**: Real-time `git show` of the selected commit.
    - **Actions**: `Enter` to view full diff, `Ctrl-Y` to copy hash, `Ctrl-X` to copy message, and `Ctrl-O` to checkout.
    - **Layout**: Perfectly aligned columns for Hash, Age, Author, and Message.

---

Made with ❤️ by `adityastomar67`
