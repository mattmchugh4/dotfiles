#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOTFILES_REPO="git@github.com:mattmchugh4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BREW_INSTALL_URL="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
OMZ_INSTALL_URL="sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
STARSHIP_INSTALL_URL="curl -sS https://starship.rs/install.sh | sh -s -- --yes"

# --- Helper Functions ---

# Installs Homebrew on macOS if not found
install_brew_if_needed() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        eval "$BREW_INSTALL_URL"
        # Add brew to PATH for Apple Silicon Macs
        if [ -f "/opt/homebrew/bin/brew" ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
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
        grep      # GNU grep
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
        bat       # On Debian/Ubuntu, this is often the 'batcat' binary
        fzf
        htop
        rename
        thefuck
        tree
        curl
        wget
    )

    echo "Linux/WSL detected. Installing packages with APT..."
    sudo apt update
    sudo apt install -y "${packages[@]}"

    # Handle bat vs batcat naming convention on Debian/Ubuntu
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
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

# Installs act (GitHub Actions local runner) on both macOS and Linux/WSL
install_act() {
    if command -v act &> /dev/null; then
        echo "act already installed."
        return 0
    fi

    echo "Installing act (GitHub Actions local runner)..."

    if [[ "$(uname -s)" == "Darwin" ]]; then
        # macOS installation using Homebrew
        echo "Installing act via Homebrew on macOS..."
        brew install act
    elif [[ "$(uname -s)" == "Linux" ]]; then
        # Linux/WSL installation
        echo "Installing act on Linux/WSL..."
        local act_version="0.2.55"  # You can update this version as needed
        local download_url="https://github.com/nektos/act/releases/download/v${act_version}/act_Linux_x86_64.tar.gz"

        # Check if it's ARM64
        if [[ "$(uname -m)" == "aarch64" ]]; then
            download_url="https://github.com/nektos/act/releases/download/v${act_version}/act_Linux_arm64.tar.gz"
        fi

        mkdir -p "$HOME/.local/bin"
        curl -L "$download_url" | tar -xz -C "$HOME/.local/bin" act
        chmod +x "$HOME/.local/bin/act"
        echo "✅ act installed to $HOME/.local/bin/act"
    else
        echo "Unsupported OS for act installation: $(uname -s)"
        return 1
    fi

    # Verify installation
    if command -v act &> /dev/null; then
        echo "✅ act installation verified successfully."
        echo "   Version: $(act --version)"
    else
        echo "⚠️  act installed but not found in PATH. You may need to add $HOME/.local/bin to your PATH."
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
    if ! command -v starship &> /dev/null; then
        echo "Installing Starship..."
        eval "$STARSHIP_INSTALL_URL"
    else
        echo "Starship already installed."
    fi
}

# Backs up existing files and then creates symlinks using stow
stow_dotfiles() {
    echo "Stowing dotfiles..."
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Error: Dotfiles directory not found at $DOTFILES_DIR" >&2
        exit 1
    fi

    # Define the list of applications to stow. Add more here as needed.
    local packages_to_stow=(
        zsh
        starship
        git
    )

    # Use a subshell to change directory temporarily
    (
        cd "$DOTFILES_DIR" || exit

        # Loop through each package to check for conflicts
        for pkg in "${packages_to_stow[@]}"; do
            echo "Checking for conflicts for '$pkg'..."
            # Find dotfiles inside the package directory (e.g., zsh/.zshrc)
            # -maxdepth 1 prevents it from looking in sub-folders of the package
            dotfiles_in_pkg=$(find "$pkg" -maxdepth 1 -type f -name ".*")

            for dotfile in $dotfiles_in_pkg; do
                target_file="$HOME/$(basename "$dotfile")"

                # If the target file exists AND is NOT a symlink, back it up.
                if [ -f "$target_file" ] && ! [ -L "$target_file" ]; then
                    echo "  -> Found existing file at $target_file. Backing it up to ${target_file}.bak"
                    mv "$target_file" "${target_file}.bak"
                fi
            done
        done

        # Now, stow the packages. --restow helps fix any incorrect existing links.
         echo "Running stow for: ${packages_to_stow[*]}"
stow --restow --target="$HOME" "${packages_to_stow[@]}"
        echo "✅ Dotfiles stowed successfully."
    )
}

# --- Main Script Execution ---

echo "Starting dotfiles setup..."

# 1. Check for Git
if ! command -v git &> /dev/null; then
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

# 4. Install act (GitHub Actions local runner)
install_act

# 5. Stow your dotfiles (run this after installing stow)
stow_dotfiles

# 6. Install Oh My Zsh (run after stowing .zshrc)
install_oh_my_zsh_if_needed

# 7. Install Starship
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
    echo "- Ensure '$HOME/.local/bin' is in your PATH for the 'bat' and 'act' commands to work."
fi

echo ""
echo "--- act (GitHub Actions Local Runner) ---"
echo "✅ act has been installed and is ready to use!"
echo "   Usage examples:"
echo "   - act -l                    # List all actions in your workflow"
echo "   - act push                  # Run the 'push' event workflow"
echo "   - act pull_request          # Run the 'pull_request' event workflow"
echo "   - act --help                # Show all available options"
echo ""
echo "   Note: act requires Docker to be installed and running."
echo "   - On macOS: Install Docker Desktop from https://www.docker.com/products/docker-desktop"
echo "   - On WSL: Install Docker Engine or Docker Desktop for Windows"

echo "========================================================="