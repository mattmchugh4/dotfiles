# --- Cursor Agent Fix ---
# Skips loading the rest of the config for the non-interactive Cursor Agent.
if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
  return
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
export ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
export ENABLE_CORRECTION="true"

# not sure if this actually works, need to test
# Disable autocorrection specifically for 'ssh'
alias ssh='ssh'

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
export plugins=(
  git
  sudo
  z
  ssh
  macos
  fzf
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# --- User Configuration & Cross-Platform Adaptations ---

# Homebrew Integration (cross-platform), Works on macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: Check for Homebrew paths
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
elif [[ "$(uname)" == "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

eval "$(starship init zsh)"
eval "$(thefuck --alias)"

# For Go binaries
export PATH="$HOME/go/bin:$PATH"

# Platform-specific PATH additions
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS specific paths
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
elif [[ "$(uname)" == "Linux" ]]; then
  # Linux/WSL specific paths
  export PATH="$HOME/.local/bin:$PATH"
fi

# Add any other custom aliases here,

# Environment Variables
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Transient Plugin, and configuration (cross-platform via Homebrew)
if command -v brew &>/dev/null; then
  # Use Homebrew version (works on both macOS and Linux)
  brew_prefix="$(brew --prefix)"
  if [ -f "$brew_prefix/share/zsh-transient-prompt/transient-prompt.zsh-theme" ]; then
    source "$brew_prefix/share/zsh-transient-prompt/transient-prompt.zsh-theme"
    export TRANSIENT_PROMPT_TRANSIENT_PROMPT='> '
  else
    echo "⚠️  Warning: zsh-transient-prompt not found at $brew_prefix/share/zsh-transient-prompt/transient-prompt.zsh-theme"
    echo "   Run: brew install olets/tap/zsh-transient-prompt"
  fi
else
  echo "⚠️  Warning: Homebrew not found. zsh-transient-prompt requires Homebrew."
  echo "   Install Homebrew: https://brew.sh"
  echo "   Then run: brew install olets/tap/zsh-transient-prompt"
fi

# The next line enables the Google Cloud CLI
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# Prevents zsh from trying to autocorrect the 'ssh' command to '.ssh'.
export CORRECT_IGNORE=(ssh)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# System info function
sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | xargs)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $2}')"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Temperature: $(vcgencmd measure_temp | awk -F'[=']' '{printf "%.1f°F\n", ($2 * 9/5) + 32}')"
}

# Network info function
netinfo() {
    echo "=== Network Information ==="
    echo "External IP: $(curl -s ifconfig.me)"
    echo "Internal IP: $(hostname -I)"
    echo "Gateway: $(ip route | grep default | awk '{print $3}')"
    echo "DNS: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"
}


# MUST BE SOURCED AT THE END
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
