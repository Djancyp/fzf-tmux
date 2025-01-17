#!/bin/bash
# cSpell:words elif

if [ "$1" = "-h" ] || [ "$1" == "--help" ]; then
	printf "\n"
	printf "\033[1m  t - the smart tmux session manager\033[0m\n"
	printf "\033[37m  https://github.com/joshmedeski/t-smart-tmux-session-manager\n"
	printf "\n"
	printf "\033[32m  Run interactive mode\n"
	printf "\033[34m      t\n"
	printf "\n"
	printf "\033[32m  Go to session\n"
	printf "\033[34m      t {name}\n"
	printf "\n"
	printf "\033[32m  Open popup (while in tmux)\n"
	printf "\033[34m      <prefix>+T\n"
	printf "\n"
	printf "\033[32m  Show help\n"
	printf "\033[34m      t -h\n"
	printf "\033[34m      t --help\n"
	printf "\n"
elif [ $# -eq 0 ]; then
	FZF_BORDER_LABEL=" t - smart tmux session manager "
	HEADER="ctrl-a all / ctrl-s sessions / ctrl-x zoxide"
	PROMPT="All> "
	ALL_BINDING="ctrl-a:change-prompt(All> )+reload(tmux list-sessions -F '#S' && zoxide query -l)"
	SESSION_BINDING="ctrl-s:change-prompt(Sessions> )+reload(tmux list-sessions -F '#S')"
	ZOXIDE_BINDING="ctrl-x:change-prompt(Zoxide> )+reload(zoxide query -l)"
	if [ "$TMUX" = "" ]; then       # if not currently in tmux
		if tmux info &>/dev/null; then # if tmux is running
			ZOXIDE_RESULT=$( (tmux list-sessions -F '#S' && zoxide query -l) | \
                fzf \
                 --reverse \
                --prompt "$PROMPT" \
                --bind "$ALL_BINDING" \
                --bind "$SESSION_BINDING" \
                --bind "$ZOXIDE_BINDING"  \
                --margin=5%,2%,2%,5% \
                --border=rounded \
                --pointer='→' \
                --header='CTRL-c or ESC to quit' \
                --prompt='Search: ' \
                --header "$HEADER")		
        else # tmux is not running
			ZOXIDE_RESULT=$(zoxide query -l | 
                fzf \
                --reverse \
                --prompt "$PROMPT" \
                --bind "$ALL_BINDING" \
                --bind "$SESSION_BINDING" \
                --bind "$ZOXIDE_BINDING"  \
                --margin=5%,2%,2%,5% \
                --border=rounded \
                --pointer='→' \
                --header='CTRL-c or ESC to quit' \
                --prompt='Search: ' \
                --header "$HEADER")
		fi
	else # currently in tmux
		ZOXIDE_RESULT=$( (tmux list-sessions -F '#S' && zoxide query -l) | fzf-tmux -p --reverse --prompt "$PROMPT" --bind "$ALL_BINDING" --bind "$SESSION_BINDING" --bind "$ZOXIDE_BINDING" --header "$HEADER")
	fi
else
	ZOXIDE_RESULT=$(zoxide query "$1")
fi

if [ "$ZOXIDE_RESULT" = "" ]; then
	exit # exit silently if no result
fi

FOLDER=$(basename "$ZOXIDE_RESULT")
SESSION_NAME=$(echo "$FOLDER" | tr ' ' '_' | tr '.' '_' | tr ':' '_')

SESSION=$(tmux list-sessions -F '#S' | grep "^$SESSION_NAME$") # find existing session

if [ "$TMUX" = "" ]; then             # if not currently in tmux
	if [ "$SESSION" = "" ]; then         # session does not exist
		cd "$ZOXIDE_RESULT" || exit 1       # jump to directory
		tmux new-session -s "$SESSION_NAME" # create session and attach
	else                                 # session exists
		tmux attach -t "$SESSION"           # attach to session
	fi
else                                     # currently in tmux
	if [ "$SESSION" = "" ]; then            # session does not exist
		cd "$ZOXIDE_RESULT" || exit 1          # jump to directory
		tmux new-session -d -s "$SESSION_NAME" # create session
		tmux switch-client -t "$SESSION_NAME"  # attach to session
	else                                    # session exists
		tmux switch-client -t "$SESSION"       # switch to session
	fi
fi
