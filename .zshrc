## PATH
#export PYTHONPATH=/usr/local/lib/python2.7/site-packages/
#export PATH=/usr/local/bin:/sbin:/usr/sbin:/usr/local/share/python/:$PATH
#export PATH=$PATH:/Users/dai/bin/android-sdk-macosx/platform-tools
#export WORKON_HOME=$HOME/.virtualenvs
#source `which virtualenvwrapper.sh`

## LANG
export LANG=ja_JP.UTF-8

## Git
autoload -Uz VCS_INFO_get_data_git; VCS_INFO_get_data_git 2> /dev/null

setopt prompt_subst
setopt re_match_pcre

function rprompt-git-current-branch {
        local name st color gitdir action
        if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
                return
        fi
        name=`git rev-parse --abbrev-ref=loose HEAD 2> /dev/null`
        if [[ -z $name ]]; then
                return
        fi

        gitdir=`git rev-parse --git-dir 2> /dev/null`
        action=`VCS_INFO_git_getaction "$gitdir"` && action="($action)"

        st=`git status 2> /dev/null`
	if [[ "$st" =~ "(?m)^nothing to" ]]; then
                color=%F{green}
	elif [[ "$st" =~ "(?m)^nothing added" ]]; then
                color=%F{yellow}
	elif [[ "$st" =~ "(?m)^# Untracked" ]]; then
                color=%B%F{red}
        else
                 color=%F{red}
         fi

              
        echo "$color$name$action%f%b "
}

## Default shell configuration
#
# set prompt
#
autoload colors
colors
case ${UID} in
0)
    PROMPT="%{${fg[cyan]}%}$(echo ${HOST%%.*} | tr '[a-z]' '[A-Z]') %B%{${fg[red]}%}%/#%{${reset_color}%}%b "
    PROMPT2="%B%{${fg[red]}%}%_#%{${reset_color}%}%b "
    RPROMPT='[`rprompt-git-current-branch`%~]'
    SPROMPT="%B%{${fg[red]}%}%r is correct? [n,y,a,e]:%{${reset_color}%}%b "
    ;;
*)
    PROMPT="%{${fg[red]}%}%/%%%{${reset_color}%} "
    PROMPT2="%{${fg[red]}%}%_%%%{${reset_color}%} "
    RPROMPT='[`rprompt-git-current-branch`%~]'
    SPROMPT="%{${fg[red]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "
    [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] && 
        PROMPT="%{${fg[cyan]}%}$(echo ${HOST%%.*} | tr '[a-z]' '[A-Z]') ${PROMPT}"
    ;;
esac

# auto change directory
#
setopt auto_cd

# auto directory pushd that you can get dirs list by cd -[tab]
#
setopt auto_pushd

# command correct edition before each completion attempt
#
setopt correct
setopt correct_all

# compacked complete list display
#
setopt list_packed

# no remove postfix slash of command line
#
#setopt noautoremoveslash



## Keybind configuration
# historical backward/forward search with linehead string binded to ^P/^N
#
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end

# reverse menu completion binded to Shift-Tab
#
bindkey "\e[Z" reverse-menu-complete


## Command history configuration
#
HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data


## Completion configuration
#
setopt   auto_list auto_param_slash list_packed rec_exact
unsetopt list_beep
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors 'di=1;34'
zstyle ':completion:*' format '%F{white}%d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' remote-access false
zstyle ':completion:*' completer _oldlist _complete _match _ignored \
    _list _history
zstyle ':completion:sudo:*' environ PATH="$SUDO_PATH:$PATH"
autoload -U compinit
compinit

# incremental completion
    function () { # precompile
        local A
        A=~/.auto-fu.zsh
        [[ -e "${A:r}.zwc" ]] && [[ "$A" -ot "${A:r}.zwc" ]] ||
        zsh -c "source $A; auto-fu-zcompile $A ${A:h}" >/dev/null 2>&1
    }
    source ~/.auto-fu; auto-fu-install

    zstyle ':auto-fu:highlight' input bold
    zstyle ':auto-fu:highlight' completion fg=white,dim
    zstyle ':auto-fu:highlight' completion/one fg=blue,dim
    zstyle ':auto-fu:var' postdisplay ''
    zstyle ':auto-fu:var' track-keymap-skip opp

    function zle-line-init () { auto-fu-init }; zle -N zle-line-init
    # zle -N zle-keymap-select auto-fu-zle-keymap-select

    function afu+cancel () {
        afu-clearing-maybe
        ((afu_in_p == 1)) && { afu_in_p=0; BUFFER="$buffer_cur"; }
    }
    zle -N afu+cancel
    function bindkey-advice-before () {
        local key="$1"
        local advice="$2"
        local widget="$3"
        [[ -z "$widget" ]] && {
            local -a bind
            bind=(`bindkey -M main "$key"`)
            widget=$bind[2]
        }
        local fun="$advice"
        if [[ "$widget" != "undefined-key" ]]; then
            local code=${"$(<=(cat <<"EOT"
                function $advice-$widget () {
                    zle $advice
                    zle $widget
                }
                fun="$advice-$widget"
EOT
            ))"}
            eval "${${${code//\$widget/$widget}//\$key/$key}//\$advice/$advice}"
        fi
        zle -N "$fun"
        bindkey -M afu "$key" "$fun"
    }
    bindkey-advice-before "^G" afu+cancel
    bindkey-advice-before "^[" afu+cancel
    bindkey-advice-before "^J" afu+cancel afu+accept-line

    # delete unambiguous prefix when accepting line
    function afu+delete-unambiguous-prefix () {
        afu-clearing-maybe
        local buf; buf="$BUFFER"
        local bufc; bufc="$buffer_cur"
        [[ -z "$cursor_new" ]] && cursor_new=-1
        [[ "$buf[$cursor_new]" == ' ' ]] && return
        [[ "$buf[$cursor_new]" == '/' ]] && return
        ((afu_in_p == 1)) && [[ "$buf" != "$bufc" ]] && {
            # there are more than one completion candidates
            zle afu+complete-word
            [[ "$buf" == "$BUFFER" ]] && {
                # the completion suffix was an unambiguous prefix
                afu_in_p=0; buf="$bufc"
            }
            BUFFER="$buf"
            buffer_cur="$bufc"
        }
    }
    zle -N afu+delete-unambiguous-prefix
    function afu-ad-delete-unambiguous-prefix () {
        local afufun="$1"
        local code; code=$functions[$afufun]
        eval "function $afufun () { zle afu+delete-unambiguous-prefix; $code }"
    }
    afu-ad-delete-unambiguous-prefix afu+accept-line
    afu-ad-delete-unambiguous-prefix afu+accept-line-and-down-history
    afu-ad-delete-unambiguous-prefix afu+accept-and-hold


## Alias configuration
#
# expand aliases before completing
#
setopt complete_aliases     # aliased ls needs if file/dir completions work

alias where="command -v"
alias j="jobs -l"

case "${OSTYPE}" in
freebsd*|darwin*)
    alias ls="ls -G -w"
    ;;
linux*)
    alias ls="ls --color"
    ;;
esac

alias la="ls -ah"
alias lf="ls -Fh"
alias ll="ls -lh"

alias du="du -h"
alias df="df -h"

alias su="su -l"


## terminal configuration
#
case "${TERM}" in
screen)
    TERM=xterm
    ;;
esac

case "${TERM}" in
xterm|xterm-color)
    export LSCOLORS=exfxcxdxbxegedabagacad
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
    ;;
kterm-color)
    stty erase '^H'
    export LSCOLORS=exfxcxdxbxegedabagacad
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
    ;;
kterm)
    stty erase '^H'
    ;;
cons25)
    unset LANG
    export LSCOLORS=ExFxCxdxBxegedabagacad
    export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=;34;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
    ;;
jfbterm-color)
    export LSCOLORS=gxFxCxdxBxegedabagacad
    export LS_COLORS='di=01;36:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors 'di=;36;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
    ;;
esac

# set terminal title including current directory
#
case "${TERM}" in
xterm|xterm-color|kterm|kterm-color)
    precmd() {
        echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
    }
    ;;
esac


## load user .zshrc configuration file
#
[ -f ${HOME}/.zshrc.mine ] && source ${HOME}/.zshrc.mine
