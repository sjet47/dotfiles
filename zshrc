###########################################################
#                  Environment Variables                  #
###########################################################

## Exported

# You may need to manually set your language environment
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

# Mirror source from TaoBao for NVM
export NVM_NODEJS_ORG_MIRROR="https://npm.taobao.org/mirrors/node/"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# PATH
# PATH=$PATH:$NEWPATH
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$PYENV_PATH/bin"
PATH="$PATH:$PYENV_PATH/shims"
PATH="$PATH:$GOPATH/bin"
export PATH

## Internal

# Pkg manager update log path
UPDATE_LOG="$HOME/.local/log/update"

# Local executable path
LBP="$HOME/.local/bin"

# Backup path
BACKUP_DIR="$HOME/.backup"

# Archive path
ARCHIVE_DIR="$HOME/.backup"

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
  # oh-my-zsh
  sourceExist "$ZSH/oh-my-zsh.sh"

  # zsh-autosuggestions-plugin bindkey
  bindkey '`' autosuggest-accept

  # zsh-mcfly plugin
  eval "$(mcfly init zsh)"

  # starship prompt
  eval "$(starship init zsh)"

  # Rust Cargo
  sourceExist "$HOME/.cargo/env"

  # Haskell Ghcup
  sourceExist "$HOME/.ghcup/env"

  # Python pyenv
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  # Get distribution name
  os_name=$(uname)
  if [[ $os_name == "Linux" ]]; then
    disv=$(cat /etc/issue | awk '{print $1}')
  elif [[ $os_name == "Darwin" ]]; then
    disv="macOS"
  fi

  # Set flag
  LOAD_ONCE=true
fi

###########################################################
#                    User  Definitions                    #
###########################################################

# PKG update base on OS
if [[ $disv == "Arch" ]]; then
  pkgupdate() {
    yay -Syyu --logfile "$UPDATE_LOG/yay/$1"
  }
elif [[ $disv == "Ubuntu" ]]; then
  pkgupdate() {
    sudo apt update | ts | tee "$UPDATE_LOG/apt/$1"
    sudo apt upgrade -y | ts | "tee -a $UPDATE_LOG/apt/$1"
  }
elif [[ $disv == "macOS" ]]; then
  alias uname="guname"
  pkgupdate() {
    brew update | tee "$UPDATE_LOG/brew/$1"
    brew upgrade | tee -a "$UPDATE_LOG/brew/$1"
    brew upgrade --cask --greedy | tee -a "$UPDATE_LOG/brew/$1"
  }
fi

# Full update
update() {
  workpath=$(pwd)
  logname=$(date "+%Y%m%d_%H%M%S").log

  # Update with system package manager
  pkgupdate "$logname"
  # Update with pip(Python)
  #python3 -m pip --log "$UPDATE_LOG/pip/$logname" install --upgrade pip
  # Update with rustup(Rust)
  rustup update

  # Pull latest dotfiles
  echo Pulling dotfiles
  cd "$HOME/dotfiles" && git pull origin main
  # Update zsh plugin
  echo Pulling zsh-autosuggestions
  cd "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" && git pull
  echo Pulling zsh-completions
  cd "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" && git pull
  echo Pulling zsh-highlighting
  cd "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" && git pull

  # Update oh-my-zsh
  cd "$HOME" && omz update
  sourceExist "$HOME/.zshrc"
  cd "$workpath" || return
}

# Edit zsh profile
alias erc='nvim $HOME/.zshrc'
alias relrc='source $HOME/.zshrc'

# General
alias ..="cl .."
alias mkdir="mkdir -p -v"
alias mv="mv -v"
alias cp="cp -v"
alias rm="rm -i -v"
alias ln="ln -v"
alias md="mkdir -v"
alias df="df -h"
alias l="lsd"
alias la="lsd -a"
alias ll="lsd -lh"
alias lla="lsd -lha"
alias rs="rsync -avz"
alias tar="tar -v"
alias cat="bat -p"

mc() {
  mkdir "$1"
  cd "$1" || return
}
cl() {
  cd $1 || return
  lsd
}

# Utility
alias v="vim"
alias nv="nvim"
alias vm="vifm"
alias grep="grep --color=auto"
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"
alias weather="curl --noproxy '*' wttr.in"
alias wrapQuote='sed "s/\(.*\)/\"\1\"/"'
alias wordmatch="cat /usr/share/dict/words | rg"
alias curtime='date "+%Y-%m-%dT%H:%M:%S%:z"'

bak() { mv "$1" "$1".bak; }
ubak() {
  file=${1/\.bak/}
  mv "$1" "$file"
}
rmDS_Store() {
  fd .DS_Store "$1" -H | sed "s/\(.*\)/\"\1\"/" | xargs rm -v
}

port() { ss -nap | grep "$1" | less; }

md5verify() { md5sum "$1" | grep -f "$1".md5; }
timestamp() {
  date "+%Y-%m-%dT%H:%M:%S%:z" >/tmp/timestamp
  xclip -i /tmp/timestamp
}
llog() {
  latest=$(ls "$1" | sort | tail -n 1)
  less "$1/$latest"
}
wgetbin() {
  wget "$1" -O "$LBP/$2"
  chmod +x "$LBP/$2"
}

# Tool wrapper
alias gb2utf8="enca -L zh_CN -x UTF-8"
alias rcs="rclone sync -P --multi-thread-streams 12"
te() { tar -vxzf "$1"; }
tg() { tar -vczf "$1".tar.gz "$1"; }
h2m() { curl "$1" | html2text --mark-code >"$2.md"; }
plsh() { pls show "$1" | bat; }
cvh264() { ffmpeg -hwaccel cuvid -c:v h264_cuvid -i "$2" -c:v h264_nvenc -crf "$1" -c:a copy "$3"; }
mkbak() { rsync -av "$1" $BACKUP_DIR/$1; }
arc() {
  7z a "$1".7z "${@:2}"
  mv "$1".7z "$ARCHIVE_DIR/"
  rm -rf "${@:2}"
}

welcome() {
  echo "$(uname -o) $(uname -r) $(uname -m)
Hello, $(whoami)! Now is $(date "+%Y-%m-%d %H:%M:%S%z")
System $(uptime)\nCurrent in [$(uname -n)]$(pwd)" | lolcat -ad 1 -S 128 -s 100 -p 5 -F 0.5
  lsd
}

# Build and debug
alias cmm="cmake"
alias cmn="cmake -GNinja"
alias mj="make -j"
alias nj="ninja -j"

alias rc="rustc"
alias co="cargo"
alias coc="cargo check"
alias cor="cargo run"
alias cob="cargo build"

alias py="python"
alias py3="python3"
alias pip="python -m pip"

alias gdb="gdb -tui -q"
alias leakchk="valgrind --tool=memcheck --leak-check=full --vgdb=no"

mje() {
  make -j "$1" "$2"
  ./"$2"
}
mjd() {
  make -j "$1" "$2"
  gdb ./"$2"
}
nje() {
  ninja -j "$1" "$2"
  ./"$2"
}
njd() {
  ninja -j "$1" "$2"
  gdb ./"$2"
}

# Wezterm
alias wt="wezterm"
alias ewt='nvim $HOME/.wezterm.lua'

# Git
alias gst="git status"
alias gad="git add"
alias gcm="git commit"
alias gps="git push"
alias gpl="git pull"
alias gsw="git switch"
alias gdf="git diff"
alias gcl="git clone"
alias glg="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gsq="git rebase -i"

ghc() { git clone --recurse-submodules "https://github.com/$1.git"; }
ghcs() { git clone --recurse-submodules "git@github.com:$1.git"; }

# Tmux
alias etc='vim $HOME/.tmux.conf'
alias t="tmux"
alias tl="tmux ls"
alias ta="tmux attach -t"
alias tk="tmux kill-session -t"
alias tn="tmux new -s"
alias td="tmux detach"

# Docker
alias dk="docker"
alias dkc="docker-compose"
alias dki="docker image"

dke() { docker exec -it "$2" bash; }
dkrd() { docker run -d "$1"; }
dkrt() { docker run -it "$1" /bin/bash; }
dktgali() { docker tag "$1" "registry.cn-hangzhou.aliyuncs.com/sjet/$2:$3"; }
dkpsali() { docker push "registry.cn-hangzhou.aliyuncs.com/sjet/$1:$2"; }
dkplali() { docker pull "registry.cn-hangzhou.aliyuncs.com/sjet/$1:$2"; }

# Local profile
sourceExist "$HOME/.profile"

## Pre-execute command
if [[ -z $RELOAD ]]; then
  welcome
  RELOAD=1
fi
