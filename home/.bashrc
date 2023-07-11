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

# shit
if [ -f data/data/com.termux/files/usr/lib/libOpenCL.so ]; then
  export LD_PRELOAD=$LD_PRELOAD:/data/data/com.termux/files/usr/lib/libOpenCL.so
fi