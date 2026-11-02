# T3 Code starts its remote server with `sh -l -s -- <key>`. The devbox /etc/profile loads
# bash-only files, so dash exits before T3's script runs. Run exactly that command in bash.
if [[ -n $SSH_CONNECTION && $ZSH_EXECUTION_STRING =~ '^sh -l -s -- [0-9a-f]{16}$' ]]; then
  exec bash -l -s -- "${ZSH_EXECUTION_STRING##* }"
fi
