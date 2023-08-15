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
[ -d "/data/openpilot" ] && cd /data/openpilot

# mathlib 
export MATHLIB="m"

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/system/vendor/lib64:/system/lib64
export LD_PRELOAD=${LD_PRELOAD}:/vendor/lib64/libOpenCL.so

RED='\033[0;31m'
NONE='\033[0m'
echo -e "Use ${RED}tmux a${NONE} to attach to a session"