_lab_pwd() { local p="${PWD%/}"; p="${p:-/}"; echo "${p/#$HOME/\~}"; }
if [ "$EUID" -eq 0 ]; then
    _USER_FG='\[\e[38;5;52m\]'
else
    _USER_FG='\[\e[38;5;232m\]'
fi
PS1="\[\e[48;5;251m\]${_USER_FG} \u \[\e[0m\]\[\e[1m\] \$(_lab_pwd) \[\e[0m\]\[\e[38;5;251m\]❯\[\e[0m\] "
