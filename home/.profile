alias less='less -r'   # raw control characters
alias whence='type -a' # where, of a sort

# Some shortcuts for different directory listings
alias ls-perms='stat -c "%a %n"'
#alias perms='stat -c "%a"'

alias ..='cd ..'         # Go up one directory
alias cd..='cd ..'       # Common misspelling for going up one directory
alias ...='cd ../..'     # Go up two directories
alias ....='cd ../../..' # Go up three directories
alias -- -='cd -'        # Go back

alias ls='ls --color=auto'
alias la='ls -A'
alias ll='ls -alF'
