#!/bin/bash

# --- Configuration ---
DOTFILES_REPO="git@github.com:mattmchugh4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BREW_INSTALL_URL="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
OMZ_INSTALL_URL="sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
STARSHIP_INSTALL_URL="curl -sS https://starship.rs/install.sh | sh"

# --- Helper Functions ---
install_brew_if_needed() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        eval "$BREW_INSTALL_URL"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile # Add brew to PATH for M1 Macs
        eval "$(/opt/homebrew/bin/brew shellenv)" # Source immediately
    else
        echo "Homebrew already installed."
    fi
}

install_oh_my_zsh_if_needed() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh not found. Installing Oh My Zsh..."
        # --unattended: Install without user interaction.
        # --keep-zshrc: Keep your existing .zshrc (important for Starship config).
        eval "$OMZ_INSTALL_URL" "" --unattended --keep-zshrc
    else
        echo "Oh My Zsh already installed."
    fi
}

install_starship_if_needed() {
    if ! command -v starship &> /dev/null; then
        echo "Starship not found. Installing Starship..."
        eval "$STARSHIP_INSTALL_URL"
    else
        echo "Starship already installed."
    fi
}

stow_dotfiles() {
    echo "Changing to dotfiles directory: $DOTFILES_DIR"
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
        exit 1
    fi
    cd "$DOTFILES_DIR" || { echo "Failed to change directory."; exit 1; }

    echo "Stowing dotfiles packages..."
    # Stow each package. Add/remove as per your setup.
    stow zsh
    stow starship
    stow git
    stow vim # if you have a vim package
    stow tmux # if you have a tmux package
    # ... add other packages here ...

    echo "Dotfiles packages stowed."
}

# --- Main Script Execution ---

echo "Starting dotfiles setup..."

# 1. Install Git if not present (macOS usually prompts, but good to check)
if ! command -v git &> /dev/null; then
    echo "Git not found. Please install Git (e.g., via Xcode Command Line Tools or Homebrew) and re-run."
    exit 1
fi

# 2. Clone the dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Dotfiles repository already exists at $DOTFILES_DIR. Pulling latest changes..."
    cd "$DOTFILES_DIR"
    git pull origin main # Or 'master'
    cd "$HOME" # Change back to home
fi

# 3. Ensure Homebrew is installed (macOS specific)
if [[ "$(uname -s)" == "Darwin" ]]; then
    install_brew_if_needed
fi

# 4. Install Stow
if ! command -v stow &> /dev/null; then
    echo "Stow not found. Installing Stow..."
    if [[ "$(uname -s)" == "Darwin" ]]; then
        brew install stow
    elif [[ "$(uname -s)" == "Linux" ]]; then
        sudo apt update && sudo apt install -y stow # Example for Debian/Ubuntu
    else
        echo "Cannot install Stow automatically on this OS. Please install it manually."
        exit 1
    fi
else
    echo "Stow already installed."
fi

# 5. Stow your dotfiles (which includes your .zshrc and starship.toml)
stow_dotfiles

# 6. Install Oh My Zsh (if not present)
install_oh_my_zsh_if_needed

# 7. Install Starship (if not present)
install_starship_if_needed

echo "Dotfiles setup complete! Please restart your terminal or run 'source ~/.zshrc' for changes to take effect."