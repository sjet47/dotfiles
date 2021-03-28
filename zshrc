# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/Users/sjet/Library/Python/3.9/bin:$PATH"
export PATH="/Users/sjet/Library/Python/3.9/lib/python/site-packages:$PATH"
export PATH="/Users/sjet/Library/Python/3.8/bin:$PATH"
export PATH="/Users/sjet/Library/Python/3.8/lib/python/site-packages:$PATH"
export PATH="/Users/sjet/workspace:$PATH"
export PATH="/Users/sjet/scripts:$PATH"
export PATH="/Users/sjet/bin:$PATH"
export PATH="/Users/sjet/n2t/tools:$PATH"
export NVM_DIR="$HOME/.nvm"
export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/"
export PATH="/Users/sjet/Library/Boost/boost_1_75_0:$PATH"
export PATH="/Users/sjet/Library/Boost/boost_1_75_0/stage/lib:$PATH"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='code'
else
  export EDITOR='mvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="open -a code ~/.zshrc"
alias ohmyzsh="open -a code ~/.oh-my-zsh"
alias code="open -a code"
alias vscconfig="~/Library/Application\ Support/Code/User/"
alias buildpath="~/Library/Developer/Xcode/DerivedData"
alias sshwin="ssh -p 2322 sjet@itfs127.com"
alias mkdir="mkdir -p"
alias df="df -h"
alias ls="exa"
alias la="exa -a"
alias ll="exa -l"
# openblas is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides BLAS in Accelerate.framework.
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# For compilers to find openblas you may need to set:
export LDFLAGS="-L/usr/local/opt/openblas/lib"
export CPPFLAGS="-I/usr/local/opt/openblas/include"

# For pkg-config to find openblas you may need to set:
# export PKG_CONFIG_PATH="/usr/local/opt/openblas/lib/pkgconfig"

# Emacs Lisp files have been installed to:
# /usr/local/share/emacs/site-lisp/protobuf

# qt is keg-only, which means it was not symlinked into /usr/local,
# because Qt 5 has CMake issues when linked.

# If you need to have qt first in your PATH run:
# echo 'export PATH="/usr/local/opt/qt/bin:$PATH"' >> ~/.zshrc
export PATH="/usr/local/opt/qt/bin:$PATH"

# For compilers to find qt you may need to set:
export LDFLAGS="-L/usr/local/opt/qt/lib"
export CPPFLAGS="-I/usr/local/opt/qt/include"

# For pkg-config to find qt you may need to set:
# export PKG_CONFIG_PATH="/usr/local/opt/qt/lib/pkgconfig"

# tcl-tk is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have tcl-tk first in your PATH run:
export PATH="/usr/local/opt/tcl-tk/bin:$PATH"

# For compilers to find tcl-tk you may need to set:
export LDFLAGS="-L/usr/local/opt/tcl-tk/lib"
export CPPFLAGS="-I/usr/local/opt/tcl-tk/include"

# For pkg-config to find tcl-tk you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/tcl-tk/lib/pkgconfig"

export TK_SILENCE_DEPRECATION=1

# For the system Java wrappers to find this JDK, symlink it with
#   sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

# openjdk is keg-only, which means it was not symlinked into /usr/local,
# because it shadows the macOS `java` wrapper.

# If you need to have openjdk first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.zshrc
export PATH="/usr/local/opt/openjdk/bin:$PATH"

# For compilers to find openjdk you may need to set:
#   export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# NVM Source
export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs

# fzf

# To install useful keybindings and fuzzy completion:
# /usr/local/opt/fzf/install

# To use fzf in Vim, add the following line to your .vimrc:
# set rtp+=/usr/local/opt/fzf

# ==> openssl@1.1
# A CA file has been bootstrapped using certificates from the system
# keychain. To add additional certificates, place .pem files in
#   /usr/local/etc/openssl@1.1/certs

# and run
#   /usr/local/opt/openssl@1.1/bin/c_rehash

# openssl@1.1 is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides LibreSSL.

# If you need to have openssl@1.1 first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"' >> ~/.zshrc

# For compilers to find openssl@1.1 you may need to set:
#   export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
#   export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"

# For pkg-config to find openssl@1.1 you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# ==> readline
# readline is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides BSD libedit.

# For compilers to find readline you may need to set:
#   export LDFLAGS="-L/usr/local/opt/readline/lib"
#   export CPPFLAGS="-I/usr/local/opt/readline/include"

# For pkg-config to find readline you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/readline/lib/pkgconfig"

# ==> sqlite
# sqlite is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have sqlite first in your PATH run:
#   echo 'export PATH="/usr/local/opt/sqlite/bin:$PATH"' >> ~/.zshrc

# For compilers to find sqlite you may need to set:
#   export LDFLAGS="-L/usr/local/opt/sqlite/lib"
#   export CPPFLAGS="-I/usr/local/opt/sqlite/include"

# For pkg-config to find sqlite you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig"

# ==> python@3.8
# Python has been installed as
#   /usr/local/opt/python@3.8/bin/python3

# Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
# `python3`, `python3-config`, `pip3` etc., respectively, have been installed into
#   /usr/local/opt/python@3.8/libexec/bin

# You can install Python packages with
#   /usr/local/opt/python@3.8/bin/pip3 install <package>
# They will install into the site-package directory
#   /usr/local/lib/python3.8/site-packages

# See: https://docs.brew.sh/Homebrew-and-Python

# python@3.8 is keg-only, which means it was not symlinked into /usr/local,
# because this is an alternate version of another formula.

# If you need to have python@3.8 first in your PATH run:
#   echo 'export PATH="/usr/local/opt/python@3.8/bin:$PATH"' >> ~/.zshrc

# For compilers to find python@3.8 you may need to set:
#   export LDFLAGS="-L/usr/local/opt/python@3.8/lib"

# For pkg-config to find python@3.8 you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/python@3.8/lib/pkgconfig"

# ==> tcl-tk
# tcl-tk is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have tcl-tk first in your PATH run:
#   echo 'export PATH="/usr/local/opt/tcl-tk/bin:$PATH"' >> ~/.zshrc

# For compilers to find tcl-tk you may need to set:
#   export LDFLAGS="-L/usr/local/opt/tcl-tk/lib"
#   export CPPFLAGS="-I/usr/local/opt/tcl-tk/include"

# For pkg-config to find tcl-tk you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/tcl-tk/lib/pkgconfig"

# ==> openblas
# openblas is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides BLAS in Accelerate.framework.

# For compilers to find openblas you may need to set:
#   export LDFLAGS="-L/usr/local/opt/openblas/lib"
#   export CPPFLAGS="-I/usr/local/opt/openblas/include"

# For pkg-config to find openblas you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/openblas/lib/pkgconfig"

# ==> python@3.9
# Python has been installed as
#   /usr/local/bin/python3

# Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
# `python3`, `python3-config`, `pip3` etc., respectively, have been installed into
#   /usr/local/opt/python@3.9/libexec/bin

# You can install Python packages with
#   pip3 install <package>
# They will install into the site-package directory
#   /usr/local/lib/python3.9/site-packages

# See: https://docs.brew.sh/Homebrew-and-Python
# ==> libffi
# libffi is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# For compilers to find libffi you may need to set:
  # export LDFLAGS="-L/usr/local/opt/libffi/lib"
  # export CPPFLAGS="-I/usr/local/opt/libffi/include"

# For pkg-config to find libffi you may need to set:
  # export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"

# ==> guile
# Guile libraries can now be installed here:
#     Source files: /usr/local/share/guile/site/3.0
#   Compiled files: /usr/local/lib/guile/3.0/site-ccache
#       Extensions: /usr/local/lib/guile/3.0/extensions

# Add the following to your .bashrc or equivalent:
  export GUILE_LOAD_PATH="/usr/local/share/guile/site/3.0"
  export GUILE_LOAD_COMPILED_PATH="/usr/local/lib/guile/3.0/site-ccache"
  export GUILE_SYSTEM_EXTENSIONS_PATH="/usr/local/lib/guile/3.0/extensions"
# ==> unbound
# To have launchd start unbound now and restart at startup:
#   sudo brew services start unbound
# ==> protobuf
# Emacs Lisp files have been installed to:
#   /usr/local/share/emacs/site-lisp/protobuf
# ==> qt
# We agreed to the Qt open source license for you.
# If this is unacceptable you should uninstall.

# qt is keg-only, which means it was not symlinked into /usr/local,
# because Qt 5 has CMake issues when linked.

# If you need to have qt first in your PATH run:
  # echo 'export PATH="/usr/local/opt/qt/bin:$PATH"' >> ~/.zshrc
  # export PATH="/usr/local/opt/qt/bin:$PATH"

# For compilers to find qt you may need to set:
  # export LDFLAGS="-L/usr/local/opt/qt/lib"
  # export CPPFLAGS="-I/usr/local/opt/qt/include"

# For pkg-config to find qt you may need to set:
  # export PKG_CONFIG_PATH="/usr/local/opt/qt/lib/pkgconfig"

# ==> tor
# To have launchd start tor now and restart at login:
#   brew services start tor
# Or, if you don't want/need a background service you can just run:
#   tor
# ==> vapoursynth
# This formula does not contain optional filters that require extra dependencies.
# To use vapoursynth.core.sub, execute:
#   brew install vapoursynth-sub
# To use vapoursynth.core.ocr, execute:
#   brew install vapoursynth-ocr
# To use vapoursynth.core.imwri, execute:
#   brew install vapoursynth-imwri
# To use vapoursynth.core.ffms2, execute the following:
#   brew install ffms2
#   ln -s "../libffms2.dylib" "/usr/local/lib/vapoursynth/libffms2.dylib"
# For more information regarding plugins, please visit:
#   http://www.vapoursynth.com/doc/plugins.html

# Emacs
# To have launchd start emacs now and restart at login:
#   brew services start emacs
# Or, if you don't want/need a background service you can just run:
#   emacs

# GDB
# On 10.12 (Sierra) or later with SIP, you need to run this:
# echo "set startup-with-shell off" >> ~/.gdbinit

# ==> ncurses
# ncurses is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.

# If you need to have ncurses first in your PATH run:
#   echo 'export PATH="/usr/local/opt/ncurses/bin:$PATH"' >> ~/.zshrc

# For compilers to find ncurses you may need to set:
#   export LDFLAGS="-L/usr/local/opt/ncurses/lib"
#   export CPPFLAGS="-I/usr/local/opt/ncurses/include"

# For pkg-config to find ncurses you may need to set:
#   export PKG_CONFIG_PATH="/usr/local/opt/ncurses/lib/pkgconfig"