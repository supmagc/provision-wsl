echo $SSH_KEYS
if [[ ! -z "$SSH_KEYS" ]]; then
  for X in "$SSH_KEYS/*.ppk"; do 
    echo "$X"
#    puttygen $X -L > ~/.ssh/$(echo $X | sed 's,./,,' | sed 's/.ppk//g').pub
#    puttygen $X -O private-openssh -o ~/.ssh/$(echo $X | sed 's,./,,' | sed 's/.ppk//g').pvk
  done;
fi