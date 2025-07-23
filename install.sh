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
    cd "$DOTFILES_DIR" || exit
    git pull origin main # Or 'master'
    cd "$HOME" || exit # Change back to home
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

echo ""
echo "========================================================="
echo "Dotfiles setup complete! Your terminal prompt might not"
echo "look right yet if you don't have a Nerd Font installed."
echo "========================================================="
echo ""
echo "--- IMPORTANT: Nerd Font Installation ---"
echo "Starship requires a Nerd Font for its special symbols (like Git branch icons)."
echo "Without it, you'll see broken characters or question marks."
echo ""
echo "Recommended Nerd Fonts: MesloLGS NF, FiraCode Nerd Font, Hack Nerd Font."
echo ""

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "On macOS:"
    echo "1. Visit https://www.nerdfonts.com/font-downloads"
    echo "2. Download your preferred font (e.g., MesloLGS NF)."
    echo "3. Open the downloaded font file(s) and use Font Book to install them."
    echo "   (Alternatively, for Homebrew users: brew tap homebrew/cask-fonts && brew install --cask font-meslo-lg-nerd-font)"
    echo "4. Open your Terminal.app or iTerm2 preferences (Cmd + ,)."
    echo "5. Go to Profiles -> Text -> Font and select your newly installed Nerd Font."
elif [[ "$(uname -s)" == "Linux" ]]; then
    echo "On Linux (including WSL):"
    echo "1. Visit https://www.nerdfonts.com/font-downloads"
    echo "2. Download your preferred font (e.g., MesloLGS NF)."
    echo "3. Create a fonts directory: mkdir -p ~/.local/share/fonts"
    echo "4. Move the downloaded .ttf or .otf font files into ~/.local/share/fonts/"
    echo "5. Refresh font cache: fc-cache -fv"
    echo "6. Open your terminal emulator (e.g., Windows Terminal for WSL, Gnome Terminal, Konsole, Alacritty) preferences."
    echo "7. Go to Profile Settings -> Appearance -> Font and select your newly installed Nerd Font."
fi

echo ""
echo "After installing and setting the font, please restart your terminal or run 'source ~/.zshrc'."
echo "Enjoy your supercharged terminal!"
echo "========================================================="