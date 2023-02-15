# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
# export LS_OPTIONS='--color=auto'
# eval "$(dircolors)"
# alias ls='ls $LS_OPTIONS'
# alias ll='ls $LS_OPTIONS -l'
# alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ] | [ -x /usr/local/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

#
# Define functions
#

function parse_git_branch() {
    branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')
    echo "$branch"
}

function getDate() {
        date "+%Y/%m/%d "
}

function virtualenv_info(){
    # Get Virtual Env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi
    [[ -n "$venv" ]] && echo "(venv:$venv)"
}

# disable the default virtualenv prompt change
export VIRTUAL_ENV_DISABLE_PROMPT=1

VENV="\$(virtualenv_info)";

#
# Commandline colors
#
if [ $(id -u) -eq 0 ]; then
        export PS1="\[\033[38;5;45m\][\[$(tput sgr0)\]\[\033[38;5;39m\]$(getDate)\t]\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;9m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;44m\]\h\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;10m\]\w\[$(tput sgr0)\] \[\033[38;5;141m\]rc:\$?\[$(tput sgr0)\] \[\033[38;5;215m\]\$(parse_git_branch)\[$(tput sgr0)\] \[\033[38;5;129m\]${VENV}\[$(tput sgr0)\]\n\\$ "
else
        export PS1="\[\033[38;5;45m\][\[$(tput sgr0)\]\[\033[38;5;39m\]$(getDate)\t]\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;11m\]\u\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;44m\]\h\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;10m\]\w\[$(tput sgr0)\] \[\033[38;5;141m\]rc:\$?\[$(tput sgr0)\] \[\033[38;5;215m\]\$(parse_git_branch)\[$(tput sgr0)\] \[\033[38;5;129m\]${VENV}\[$(tput sgr0)\]\n\\$ "
fi

#
# .bash_history configuration
#
HISTSIZE=-1
HISTFILESIZE=-1
HISTTIMEFORMAT="[%y/%m/%d %T] "
if [ ! -e ~/.bash_history ]; then
        touch ~/.bash_history # create it before root
fi

#
# default editor: VIM
#
if [ -e /usr/bin/vim ]; then
        EDITOR=/usr/bin/vim
elif [ -e /usr/bin/vi ]; then
        alias vim="/usr/bin/vi"
        EDITOR=/usr/bin/vi
else
        alias vim="/usr/bin/nano"
        EDITOR=/usr/bin/nano
fi

#
# enable bash_completion module
#
#if [ -e /etc/profile.d/bash_completion.sh ]; then
#        source /etc/profile.d/bash_completion.sh
#fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#
# Extensions
#
if [ -e ~/.bashrc_extension ]; then
        . ~/.bashrc_extension
fi

#
## .vimrc
#
cat <<EOF > ~/.vimrc
syntax on
colorscheme desert
set mouse=
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
autocmd FileType yml setlocal ts=2 sts=0 sw=4
EOF

#
## .tmux.conf
#
cat <<EOF > ~/.tmux.conf
# RoBe TMUX configuration

# Remap default key to use tmux to CTRL+A
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Remap spliting panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
unbind Home
unbind End

# Remap moving between windows
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Disable delay between windows
set-option -g repeat-time 0
# Toggle mouse on
bind-key M \
  set-option -g mouse on \;\
  display-message 'Mouse: ON'

# Toggle mouse off
bind-key m \
  set-option -g mouse off \;\
  display-message 'Mouse: OFF'
EOF

# EOF

