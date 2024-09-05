###########################################################
#                  Environment Variables                  #
###########################################################

## Exported

# Language Preference
export LANG="en_US.UTF-8"

# Preferred editor
export EDITOR="vim"

# Dotfile path
export DOTFILE_DIR="$HOME/dotfiles"

# Starship DISABLE for now
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Go path
export GOPATH="$HOME/.local/go"

# Pyenv
export PYENV_SHELL="zsh"
export PYENV_PATH="$HOME/.pyenv"

# NVM path
export NVM_DIR="$HOME/.nvm"

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# gpg-agent
export GPG_TTY=$(tty)

# PATH
# PATH=$PATH:$NEWPATH
PATH="$PATH:$DOTFILE_DIR/scripts"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$PYENV_PATH/bin"
PATH="$PATH:$PYENV_PATH/shims"
PATH="$PATH:$GOPATH/bin"
PATH="$PATH:/usr/share/bcc/tools"
export PATH

## Internal

# Update log path
UPDATE_LOG="$HOME/.local/log/update"

# Backup path
BACKUP_DIR="$HOME/.backup"

# SSHFS path
SSHFS_DIR="$HOME/env"

###########################################################
#                    Zsh Configuration                    #
###########################################################

# Theme
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="powerlevel10k/powerlevel10k"

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

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
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
HIST_STAMPS="yyyy-mm-dd"

HISTFILE="$HOME/.zsh_history"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-completions zsh-autosuggestions zsh-syntax-highlighting sudo web-search)

###########################################################
#               Third-party  Configuration                #
###########################################################

sourceExist() {
  [ -f "$1" ] && source "$1"
}

# Load once, should only have non-user-defined configuration
if [[ ! $LOAD_ONCE ]]; then

  plugin_setups=(
    oh-my-zsh
    zsh-autosuggestions
    starship
    cargo
    zoxide
    atuin
    fuck
    # carapace
    # pyenv
    # ghcup
  )

  for setup in "${plugin_setups[@]}"; do
    source "$DOTFILE_DIR/plugins/$setup"
  done

  LOAD_ONCE=true
fi

###########################################################
#                    User  Definitions                    #
###########################################################

update() {
  sys_update $UPDATE_LOG
  omz update
  sourceExist "$HOME/.zshrc"
}

alias_profiles=(
  core
  utils
  dev
  git
  docker
  wezterm
  kubernetes
  #tmux
)

for profile in "${alias_profiles[@]}"; do
  source "$DOTFILE_DIR/alias/$profile"
done

# Load Local profile
sourceExist "$HOME/.profile"

## Pre-execute command
if [[ -z $RELOAD ]]; then
  welcome
  RELOAD=1
fi
