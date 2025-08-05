#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOTFILES_REPO="git@github.com:mattmchugh4/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BREW_INSTALL_URL="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
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
        zsh       # Zsh shell (may already be installed on modern macOS)
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
        zsh       # Zsh shell
        bat       # On Debian/Ubuntu, this is often the 'batcat' binary
        fzf
        htop
        rename
        thefuck
        tree
        curl
        wget
        build-essential  # Required for Homebrew
        git
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

    # Install Homebrew on Linux if not present
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew on Linux..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Determine the correct Homebrew path based on architecture
        local brew_path
        if [[ "$(uname -s)" == "Darwin" ]]; then
            # macOS
            if [[ "$(uname -m)" == "arm64" ]]; then
                # macOS on Apple Silicon
                brew_path="/opt/homebrew"
            else
                # macOS on Intel
                brew_path="/usr/local"
            fi
        else
            # Linux (both x86_64 and ARM)
            brew_path="/home/linuxbrew/.linuxbrew"
        fi

        # Set up Homebrew environment for current session
        echo "Setting up Homebrew environment..."
        eval "$($brew_path/bin/brew shellenv)"
        echo "✅ Homebrew installed and configured on Linux at $brew_path"
    else
        echo "Homebrew already installed."
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

# Checks if zsh is installed and sets it as default shell if needed
setup_zsh_shell() {
    if ! command -v zsh &> /dev/null; then
        echo "❌ Error: Zsh is not installed. Please install zsh first." >&2
        echo "   This should have been installed with the packages above." >&2
        exit 1
    fi

    echo "✅ Zsh is installed."

    # Check if zsh is already the default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo "Setting zsh as the default shell..."

        # Get the path to zsh
        local zsh_path
        zsh_path=$(command -v zsh)

        # Add zsh to /etc/shells if it's not already there
        if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
            echo "Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
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
        # Directly run the installer script via sh, passing arguments correctly
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
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
    # Check if Homebrew is available (works on both macOS and Linux)
    if command -v brew &> /dev/null; then
        # Install via Homebrew (same on both macOS and Linux)
        if ! brew list olets/tap/zsh-transient-prompt &> /dev/null; then
            echo "Installing zsh-transient-prompt via Homebrew..."
            # Add the tap if not already added
            brew tap olets/tap 2>/dev/null || true
            # Install the package
            brew install olets/tap/zsh-transient-prompt
            echo "✅ zsh-transient-prompt installed successfully via Homebrew."
        else
            echo "zsh-transient-prompt already installed via Homebrew."
        fi
    else
        echo "⚠️  Homebrew not found. zsh-transient-prompt requires Homebrew."
        echo "   Please install Homebrew first: https://brew.sh"
        return 1
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

# Check for Git
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install it manually and re-run this script." >&2
    exit 1
fi

# Clone the dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Dotfiles repository already exists. Pulling latest changes..."
    (cd "$DOTFILES_DIR" && git pull origin main)
fi

# Install packages based on OS
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

if [[ "$(uname -s)" == "Linux" ]]; then
    echo ""
    echo "--- Linux Specific Notes ---"
    echo "- Homebrew has been installed and is available for consistent package management."
    echo "- For fzf keybindings (Ctrl+R, etc.), add this to your .zshrc:"
    echo "  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh"
    echo "- Ensure '$HOME/.local/bin' is in your PATH for the 'bat' and 'act' commands to work."
    echo "- The same zsh-transient-prompt is now available via Homebrew on Linux."
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