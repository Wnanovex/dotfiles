#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

fastfetch

#alias ls='ls --color=auto'
alias ls='eza --color=auto --icons=auto'
alias eza='eza --color=auto --icons=auto'
alias ll='eza -l'
alias la='eza -lah'
alias lt='eza -T'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

eval "$(starship init bash)"
eval "$(fzf --bash)"


