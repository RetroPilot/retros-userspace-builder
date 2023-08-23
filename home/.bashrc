# all the comforts of home
alias ll="ls -al"
alias l='ls -lah'
alias gup='git pull --rebase'
alias gl='git pull'
alias gp='git push'
alias gcam='git commit -a -m'
alias gst='git status'
alias gco='git checkout'
alias gsu='git submodule update'
alias more='less'

# everyone wants to start here anyway
if [ -d "/data/flowpilot" ]; then
  export PYTHONPATH=/data/flowpilot
  cd /data/flowpilot
fi

RED='\033[0;31m'
NONE='\033[0m'
# echo -e "Use ${RED}tmux a${NONE} to attach to a session"