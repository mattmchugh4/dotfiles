#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOTFILES_REPO="git@github.com:mattmchugh4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
STARSHIP_INSTALL_URL="curl -sS https://starship.rs/install.sh | sh -s -- --yes"

# --- Package Lists ---

# 1. Core dependencies for Linux to get started (installed with apt).
#    This list should be minimal, mostly for getting Homebrew to run.
CORE_LINUX_DEPS=(
  build-essential # For compiling things, required by Homebrew
  curl
  file
  git
  procps # Provides essential Linux commands
  zsh    # We install zsh here to set it as the shell before Homebrew
)

# 2. Common packages to be installed with Homebrew on BOTH macOS and Linux.
#    This is your primary list for cross-platform tools. Add new tools here!
COMMON_BREW_PACKAGES=(
  bat        # A cat(1) clone with wings
  coreutils  # GNU File, Shell, and Text utilities
  fzf        # Command-line fuzzy finder
  grep       # GNU grep (often newer than system default)
  htop       # Interactive process viewer
  ncdu       # Disk usage analyzer
  rename     # Perl-powered file renaming utility
  shellcheck # Static analysis tool for shell scripts
  shfmt      # Shell formatter
  stow       # Symlink farm manager
  thefuck    # Corrects your previous console command
  tree       # Display directories as trees
)

# 3. Packages for macOS only (installed with brew).
#    You can add casks here, e.g., font-meslo-lg-nerd-font
MACOS_ONLY_BREW_PACKAGES=(
  # Example: mas # Mac App Store command-line interface
)

# --- Helper Functions ---

# Installs Homebrew on macOS if not found
install_brew_macos() {
  if ! command -v brew &>/dev/null; then
    echo "🍺 Homebrew not found. Installing Homebrew on macOS..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  else
    echo "🍺 Homebrew already installed."
  fi
}

# Installs Homebrew on Linux if not found
install_brew_linux() {
  # Check for brew command in the expected Linux path
  if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] || command -v brew &>/dev/null; then
    echo "🍺 Homebrew already installed."
    # Ensure it's in the PATH for the current session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    return 0
  fi

  echo "🍺 Installing Homebrew on Linux..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Single function to handle package installation for both OSes
install_packages() {
  echo "📦 Installing system packages..."

  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS detected. Setting up with Homebrew..."
    install_brew_macos

    # Combine common and macOS-specific packages
    local packages_to_install=("${COMMON_BREW_PACKAGES[@]}" "${MACOS_ONLY_BREW_PACKAGES[@]}")

    echo "Installing Brew packages: ${packages_to_install[*]}"
    brew install "${packages_to_install[@]}"

    # Install fzf key bindings and fuzzy completion
    echo "Configuring fzf for macOS..."
    "$(brew --prefix)/opt/fzf/install" --all

  elif [[ "$(uname -s)" == "Linux" ]]; then
    echo "Linux detected. Setting up core dependencies with APT..."
    sudo apt-get update
    sudo apt-get install -y "${CORE_LINUX_DEPS[@]}"

    # Now, set up Homebrew and install everything else with it
    install_brew_linux

    echo "Installing Brew packages: ${COMMON_BREW_PACKAGES[*]}"
    brew install "${COMMON_BREW_PACKAGES[@]}"

    echo "✅ To enable fzf keybindings, ensure fzf setup is sourced in your .zshrc"

  else
    echo "Unsupported OS: $(uname -s). Please install packages manually." >&2
    exit 1
  fi
  echo "✅ Package installation complete."
}

# Installs act (GitHub Actions local runner) using Homebrew for both OSes
install_act() {
  if ! command -v brew &>/dev/null; then
    echo "⚠️ Homebrew not found. Skipping act installation."
    return 1
  fi

  if brew list act &>/dev/null; then
    echo "act already installed."
    return 0
  fi

  echo "Installing act via Homebrew..."
  brew install act

  if command -v act &>/dev/null; then
    echo "✅ act installation verified successfully."
  else
    echo "❌ act installation failed."
  fi
}

# Checks if zsh is installed and sets it as default shell if needed
setup_zsh_shell() {
  # Prefer the Homebrew-installed zsh path
  local zsh_path
  if [[ "$(uname -s)" == "Darwin" ]]; then
    zsh_path="/opt/homebrew/bin/zsh"                      # Apple Silicon
    [ ! -f "$zsh_path" ] && zsh_path="/usr/local/bin/zsh" # Intel Mac fallback
  elif [[ "$(uname -s)" == "Linux" ]]; then
    zsh_path="/home/linuxbrew/.linuxbrew/bin/zsh"
  fi

  # Fallback to system zsh if Homebrew one isn't found
  if [ ! -f "$zsh_path" ]; then
    zsh_path=$(command -v zsh)
  fi

  if ! command -v zsh &>/dev/null || [ ! -f "$zsh_path" ]; then
    echo "❌ Error: Zsh is not installed. Please install zsh first." >&2
    exit 1
  fi

  echo "✅ Zsh is installed at $zsh_path"

  # Check if zsh is already the default shell
  if [[ "$SHELL" != *"$zsh_path"* ]]; then
    echo "Setting zsh as the default shell..."
    # Add zsh to /etc/shells if it's not already there
    if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
      echo "Adding $zsh_path to /etc/shells..."
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change the default shell to zsh
    echo "Changing default shell to zsh..."
    chsh -s "$zsh_path"
    echo "✅ Default shell changed to zsh. You may need to restart your terminal."
  else
    echo "✅ Zsh is already the default shell."
  fi
}

install_oh_my_zsh_if_needed() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  else
    echo "Oh My Zsh already installed."
  fi
}

install_starship_if_needed() {
  if ! command -v starship &>/dev/null; then
    echo "Installing Starship..."
    eval "$STARSHIP_INSTALL_URL"
  else
    echo "Starship already installed."
  fi
}

install_zsh_syntax_highlighting() {
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$plugin_dir" ]; then
    echo "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
    echo "✅ zsh-syntax-highlighting installed successfully."
  else
    echo "zsh-syntax-highlighting already installed."
  fi
}

install_zsh_autosuggestions() {
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$plugin_dir" ]; then
    echo "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir"
    echo "✅ zsh-autosuggestions installed successfully."
  else
    echo "zsh-autosuggestions already installed."
  fi
}

install_zsh_transient_prompt() {
  if ! command -v brew &>/dev/null; then
    echo "⚠️  Homebrew not found. zsh-transient-prompt requires Homebrew."
    return 1
  fi

  if ! brew list olets/tap/zsh-transient-prompt &>/dev/null; then
    echo "Installing zsh-transient-prompt via Homebrew..."
    brew tap olets/tap 2>/dev/null || true
    brew install olets/tap/zsh-transient-prompt
  else
    echo "zsh-transient-prompt already installed."
  fi
}

stow_dotfiles() {
  echo "Stowing dotfiles..."
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR" >&2
    exit 1
  fi

  local packages_to_stow=(zsh starship git)

  (
    cd "$DOTFILES_DIR" || exit
    # Stow the packages. --restow helps fix any incorrect existing links
    # and --no-folding prevents stow from creating subdirectories in $HOME
    echo "Running stow for: ${packages_to_stow[*]}"
    stow --restow --target="$HOME" --no-folding "${packages_to_stow[@]}"
    echo "✅ Dotfiles stowed successfully."
  )
}

# --- Main Script Execution ---

main() {
  echo "Starting dotfiles setup..."

  # Clone the dotfiles repository
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    echo "Dotfiles repository already exists. Pulling latest changes..."
    (cd "$DOTFILES_DIR" && git pull origin main)
  fi

  # Install system packages (uses apt for Linux core, then brew for everything)
  install_packages

  # Install act (GitHub Actions local runner)
  install_act

  # Stow your dotfiles (run this after installing stow)
  stow_dotfiles

  # Setup zsh shell (verify installation and set as default)
  setup_zsh_shell

  # Install Oh My Zsh (run after stowing .zshrc and setting up zsh)
  install_oh_my_zsh_if_needed

  # Install zsh plugins
  install_zsh_syntax_highlighting
  install_zsh_autosuggestions
  install_zsh_transient_prompt

  # Install Starship
  install_starship_if_needed

  # --- Final Instructions ---
  echo ""
  echo "========================================================="
  echo "✅ Dotfiles setup complete!"
  echo "========================================================="
  echo ""
  echo "--- ⚠️ IMPORTANT: Final Steps ---"
  echo "1. Install a Nerd Font (e.g., MesloLGS NF, FiraCode Nerd Font)."
  echo "   - On macOS: brew install --cask font-meslo-lg-nerd-font"
  echo "   - On Linux: See https://www.nerdfonts.com/font-downloads for instructions."
  echo "2. Set the Nerd Font in your terminal's preferences."
  echo "3. Restart your terminal or run 'source ~/.zshrc' to apply all changes."
}

# --- Run Main Function ---
main
