#!/bin/bash
# not sure what this is or where it came from, do i need it, have it on mindhop windows
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOTFILES_REPO="git@github.com:mattmchugh4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BREW_INSTALL_URL="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
OMZ_INSTALL_URL="sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
STARSHIP_INSTALL_URL="curl -sS https://starship.rs/install.sh | sh -- --yes" # Add --yes to auto-confirm

# --- Helper Functions ---

# Installs Homebrew on macOS if not found
install_brew_if_needed() {
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    eval "$BREW_INSTALL_URL"
    # Add brew to PATH for Apple Silicon Macs
    if [ -f "/opt/homebrew/bin/brew" ]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    echo "Homebrew already installed."
  fi
}

# Installs packages using Homebrew on macOS
install_brew_packages() {
  local packages=(
    stow
    bat
    coreutils # GNU core utilities
    fzf
    grep # GNU grep
    htop
    rename
    thefuck
    tree
  )

  echo "macOS detected. Installing packages with Homebrew..."
  brew install "${packages[@]}"

  # Install fzf key bindings and fuzzy completion
  echo "Configuring fzf for macOS..."
  "$(brew --prefix)/opt/fzf/install" --all
}

# Installs packages using APT on Linux/WSL
install_apt_packages() {
  local packages=(
    stow
    bat # On Debian/Ubuntu, this is often the 'batcat' binary
    fzf
    htop
    rename
    thefuck
    tree
  )

  echo "Linux/WSL detected. Installing packages with APT..."
  sudo apt update
  sudo apt install -y "${packages[@]}"

  # Handle bat vs batcat naming convention on Debian/Ubuntu
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    echo "Creating 'bat' symlink for 'batcat'..."
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "✅ Symlink created. Ensure '$HOME/.local/bin' is in your PATH."
  fi
}

# Router function to call the correct package installer
install_packages() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    install_brew_if_needed
    install_brew_packages
  elif [[ "$(uname -s)" == "Linux" ]]; then
    install_apt_packages
  else
    echo "Unsupported OS: $(uname -s). Please install packages manually."
    exit 1
  fi
}

install_oh_my_zsh_if_needed() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    eval "$OMZ_INSTALL_URL" "" --unattended --keep-zshrc
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

stow_dotfiles() {
  echo "Changing to dotfiles directory: $DOTFILES_DIR"
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR" >&2
    exit 1
  fi
  # Use a subshell to avoid needing to cd back
  (
    cd "$DOTFILES_DIR" || exit
    echo "Stowing dotfiles packages..."
    # Stow each package. Add/remove as per your setup.
    stow zsh
    stow starship
    stow git
    # ... add other packages here ...
    echo "Dotfiles stowed successfully."
  )
}

# --- Main Script Execution ---

echo "Starting dotfiles setup..."

# 1. Check for Git
if ! command -v git &>/dev/null; then
  echo "Error: Git is not installed. Please install it manually and re-run this script." >&2
  exit 1
fi

# 2. Clone the dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles repository..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  echo "Dotfiles repository already exists. Pulling latest changes..."
  (cd "$DOTFILES_DIR" && git pull origin main)
fi

# 3. Install packages based on OS
install_packages

# 4. Stow your dotfiles (run this after installing stow)
stow_dotfiles

# 5. Install Oh My Zsh (run after stowing .zshrc)
install_oh_my_zsh_if_needed

# 6. Install Starship
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

if [[ "$(uname -s)" == "Linux" ]]; then
  echo ""
  echo "--- Linux Specific Notes ---"
  echo "- For fzf keybindings (Ctrl+R, etc.), add this to your .zshrc:"
  echo "  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh"
  echo "- Ensure '$HOME/.local/bin' is in your PATH for the 'bat' command to work."
fi

echo "========================================================="
