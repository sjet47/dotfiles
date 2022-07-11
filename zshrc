###########################################################
#                   ZSH User Profile                      #
###########################################################



## Environment Variable

# PATH export PATH=$PATH:$NEWPATH
export PATH=$PATH:$HOME/.local/bin:$HOME/.script

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# NVM path
export NVM_DIR="$HOME/.nvm"

# Go path
export GOPATH="$HOME/.local/go"

# Dotfile path
export DOTFILE_DIR="$HOME/dotfiles"

# Pkg manager update log path
export UPDATE_LOG="$HOME/.local/log/update"

# Local executable path
export LBP=$HOME/.local/bin

# Mirror source from TaoBao for NVM
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node/

# Pyenv
export PYENV_SHELL=zsh

# Starship
STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Preferred editor
export EDITOR='vim'


# !Disactived!

# You may need to manually set your language environment
#export LANG=en_US.UTF-8

# Manual page path
#export MANPATH="/usr/local/man:$MANPATH"

# Compilation flags
#export ARCHFLAGS="-arch x86_64"



## ZSH Configuration

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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-completions zsh-autosuggestions zsh-syntax-highlighting sudo web-search)



## Other profiles need to load

# Local profile
source $HOME/.profile

# Oh my zsh
source $ZSH/oh-my-zsh.sh

# zsh-autosuggestions bindkey
bindkey '`' autosuggest-accept

# Powerline10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Rustup
source $HOME/.cargo/env

# pyenv
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# starship prompt
eval "$(starship init zsh)"



## User alias and function
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Get distribution name
os_name=$(uname)
if [[ $os_name == "Linux" ]]
then
  disv=$(cat /etc/issue | awk '{print $1}')
elif [[ $os_name == "Darwin" ]]
then
  disv="macOS"
fi

# PKG update

if [[ $disv == "Arch" ]]
then
	pkgupdate() {
		yay -Syyu --logfile $UPDATE_LOG/yay/$1
	}
elif [[ $disv == "Ubuntu" ]]
then
	pkgupdate() {
		sudo apt update | ts | tee $UPDATE_LOG/apt/$1
		sudo apt upgrade -y | ts | tee -a $UPDATE_LOG/apt/$1
	}
elif [[ $disv == "macOS" ]]
then
	alias uname="guname"
	pkgupdate() {
		brew update | tee $UPDATE_LOG/brew/$1
		brew upgrade | tee -a $UPDATE_LOG/brew/$1
		brew upgrade --cask --greedy | tee -a $UPDATE_LOG/brew/$1
	}
fi

update() {
		workpath=$(pwd)
		logname=$(date "+%Y%m%d_%H%M%S").log
		pkgupdate $logname
		python3 -m pip --log $UPDATE_LOG/pip/$logname install --upgrade pip
		rustup update
		cd $HOME/dotfiles
		git pull origin main
		omz update
		source $HOME/.zshrc
		cd $workpath
}

# Edit zsh profile
alias erc="vim $HOME/.zshrc"
alias relrc="source $HOME/.zshrc"

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

mc() { mkdir "$1"; cd "$1" }
cl() { cd $1; lsd }
bak() { mv "$1" "$1".bak }
ubak() { file=$(echo $1 | sed "s/\.bak//"); mv $1 $file }
mkbak() { rsync -av "$1" $HOME/.backup/$1 }

welcome() {
echo "$(uname -o) $(uname -r) $(uname -m)
Hello, $(whoami)! Now is $(date "+%Y-%m-%d %H:%M:%S%z")
System $(uptime)\nCurrent in [$(uname -n)]$(pwd)" | lolcat -ad 1 -S 128 -p 5 -F 0.5
	 lsd
}

# Environment
alias pip="python -m pip"

# Build and debug
alias cmm="cmake"
alias cmn="cmake -GNinja"
alias mj="make -j"
alias nj="ninja -j"
alias gdb="gdb -tui -q"
alias leakchk="valgrind --tool=memcheck --leak-check=full --vgdb=no"
alias rc="rustc"
alias co="cargo"
alias coc="cargo check"
alias cor="cargo run"
alias cob="cargo build"
alias py="python"
alias py3="python3"

mje() { make -j "$1" "$2"; ./"$2" }
mjd() { make -j "$1" "$2"; gdb ./"$2" }
nje() { ninja -j "$1" "$2"; ./"$2" }
njd() { ninja -j "$1" "$2"; gdb ./"$2" }

# Utility
alias v="vim"
alias vm="vifm"
alias grep="grep --color=auto"
alias busy="cat /dev/urandom | hexdump -C | grep 'ca fe'"
alias gb2utf8="enca -L zh_CN -x UTF-8"
alias weather="curl --noproxy '*' wttr.in"
alias wrapQuote='sed "s/\(.*\)/\"\1\"/"'

pid() { ps aux | grep "$1" | less }
port() { ss -nap | grep "$1" | less }
md5chk() { md5sum "$1" | grep -f "$1".md5 }
tg() { tar -vczf "$1".tar.gz "$1" }
te() { tar -vxzf "$1" }
plsh() { pls show "$1" | bat }
h2m() { curl "$1" | html2text --mark-code > "$2.md" }
llog() { latest=$(ls "$1" | sort | tail -n 1); less $1/$latest }
wgetbin() { wget "$1" -O "$LBP/$2"; chmod +x "$LBP/$2" }
cvh264() { ffmpeg -hwaccel cuvid -c:v h264_cuvid -i "$2" -c:v h264_nvenc -crf "$1" -c:a copy "$3" }

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

ghc() { git clone --recurse-submodules "https://github.com/$1.git" }
ghcs() { git clone --recurse-submodules "git@github.com:$1.git" }

# Tmux
alias etc="vim $HOME/.tmux.conf"
alias t="tmux"
alias tl="tmux ls"
alias ta="tmux attach -t"
alias tk="tmux kill-session -t"
alias tn="tmux new -s"

# Docker
alias dk="docker"

dkrd() { docker run -d $1 }
dkrt() { docker run -it $1 /bin/bash }
dkeu() { docker exec -itu $2 -w /home/$2 $1 /bin/zsh }

# Rclone
alias rcs="rclone sync -P --multi-thread-streams 12"



## Pre-execute command
if [[ -z $RELOAD ]]
then
	welcome
	RELOAD=1
fi
