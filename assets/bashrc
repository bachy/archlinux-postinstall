
#-------------------------------------------------------------
# Source global definitions (if any)
#-------------------------------------------------------------

if [ -f /etc/bashrc ]; then
  . /etc/bashrc   # --> Read /etc/bashrc, if present.
fi

if [ -f /etc/bash_completion ]; then
	    . /etc/bash_completion
fi

PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

export EDITOR=vim
export TERM=xterm-256color

# https://wiki.archlinux.org/index.php/Bash#Additional_programs_and_options_manually
complete -cf sudo
complete -cf man

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# https://wiki.archlinux.org/index.php/Bash#Auto_.22cd.22_when_entering_just_a_path
shopt -s autocd


# Only load Liquid Prompt in interactive shells, not from a script or from scp
[[ $- = *i* ]] && source ~/.liquidprompt/liquidprompt


alias ls='ls -lsh --color=always --group-directories-first --time-style=+"%d.%m.%Y %H:%M"'
alias la='ls -lsha --color=always --group-directories-first --time-style=+"%d.%m.%Y %H:%M"'
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'''

alias grep='grep --color=tty -d skip'

alias cp="cp -i"                          # confirm before overwriting something


alias df="df -kTh"                          # human-readable sizes

alias free='free -m'                      # show sizes in MB

alias sys='sudo systemctl'

alias mysqlr='mysql -u root -p'


alias ggraph="git log --graph --abbrev-commit --decorate=no --format=format:'%C(bold yellow)%ai%C(reset)%C(yellow)(%ar)%C(reset)%C(auto)%+d%C(reset)%n''%C(dim white)%an%C(reset)%n''%C(bold white)%B%C(reset)%C(blue)%H%C(reset)%n' --all"


starthttpd ()
{
    sudo systemctl start httpd
    sudo systemctl start mysqld
}

if [ -f ~/.private-aliases ]; then
    . ~/.private-aliases
fi
