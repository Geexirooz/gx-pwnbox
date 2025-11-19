# ----------------- Basic setup ----------------- #
# Not interactive? don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# ----------------- History config ----------------- #
# Ignore duplicates in history
HISTCONTROL=ignoredups
HISTSIZE=1000
HISTFILESIZE=2000
# append to the history file, don't overwrite it
shopt -s histappend

# ----------------- Set a fancy prompt ----------------- #
case "$TERM" in
xterm-color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability:
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		# We have color support; assume it's compliant with Ecma-48
		# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
		# a case would tend to support setf rather than setaf.)
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1="\[\033[0;31m\]\342\224\214\342\224\200\$([[ \$? != 0 ]] && echo \"[\[\033[0;31m\]\360\237\224\245\[\033[0;31m\]]\342\224\200\")[$(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;39m\]root\[\033[01;33m\]@\[\033[01;96m\]\h'; else echo '\[\033[0;39m\]\u\[\033[01;33m\]@\[\033[01;96m\]\h'; fi)\[\033[0;31m\]]\342\224\200[\[\033[0;32m\]\w\[\033[0;31m\]]\n\[\033[0;31m\]\342\224\224\342\224\200\342\224\200\342\225\274 \[\033[0m\]\[\e[01;33m\]\\$\[\e[0m\]"
else
	PS1='┌──[\u@\h]─[\w]\n└──╼ \$ '
fi

# ----------------- auto color aliases ----------------- #
# Set 'man' colors
if [ "$color_prompt" = yes ]; then
	man() {
		env \
			LESS_TERMCAP_mb=$'\e[01;31m' \
			LESS_TERMCAP_md=$'\e[01;31m' \
			LESS_TERMCAP_me=$'\e[0m' \
			LESS_TERMCAP_se=$'\e[0m' \
			LESS_TERMCAP_so=$'\e[01;44;33m' \
			LESS_TERMCAP_ue=$'\e[0m' \
			LESS_TERMCAP_us=$'\e[01;32m' \
			man "$@"
	}
fi

# housekeeping leftovers from fancy prompt section
unset color_prompt force_color_prompt

# Set 'ls' and 'grep' colors
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

# ----------------- Functions ----------------- #
# Load ssh keys if not loaded (useful for tmux)
share-ssh-agent() {
    local socket

    for socket in \
        "$SSH_AUTH_SOCK" \
        $(find /run/user -user $(id -u) -iregex /run/user/[0-9]+/keyring/ssh -type s 2>/dev/null) \
        $(find /tmp -user $(id -u) -iregex /tmp/ssh-[a-zA-Z0-9]+/agent.[0-9]+ -type s 2>/dev/null)
    do
        if SSH_AUTH_SOCK=$socket timeout 10 ssh-add -l &>/dev/null; then
            export SSH_AUTH_SOCK=$socket
            return
        fi
    done

    echo 'No valid SSH agents found' >&2
    return 1
}
share-ssh-agent

# ----------------- Better autocomplete ----------------- #
bind 'set colored-completion-prefix on'    # Prefix shown in colour
bind 'set colored-stats on'                # Files shown in colour in completion suggestion
bind 'set completion-ignore-case on'       # * contradictory with the next one?
bind 'set completion-map-case on'          # *
bind 'set mark-symlinked-directories on'   # Adds @ to the end of symlinks names
bind 'set match-hidden-files off'          # *
bind 'set menu-complete-display-prefix on' # *
bind 'set page-completions off'            # *
bind 'set revert-all-at-newline on'        # *
bind 'set show-all-if-ambiguous on'        #
bind 'set show-all-if-unmodified on'       #
bind 'set visible-stats on'                #
bind '"\e[A": history-search-backward'     # Type ls and up arrow, it will find all commands starting with ls
bind '"\e[B": history-search-forward'      # Same as above but in the other direction
bind 'Tab: menu-complete'                  # Menu select as in zsh
bind '"\e[Z": menu-complete-backward'      # Same as above in the other direction (shift + tab)

# ----------------- Handy aliases ----------------- #
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'
alias dd='dd status=progress'

# ----------------- Source other profiles ----------------- #
if [ -f "$HOME/.bash_aliases" ]; then
	. "$HOME/.bash_aliases"
fi

# ----------------- HTB EVs ----------------- #
TIP=""
DOM=""
U=""
P=""
