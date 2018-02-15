source "$HOME/.config/config.user.zsh"

mkdir -p -v $HOME/.ssh

if [[ ! -z "$SSH_KEYS" ]]; then
  for X in $SSH_KEYS/*.ppk; do 
    FILE=$(basename $X)
    if [[ $FILE == "default.ppk" ]]; then
      TARGET="id_rsa"
    else
      TARGET="id_rsa_${FILE/%.ppk/}"
    fi
    puttygen "$X" -L > "$HOME/.ssh/$TARGET.pub"
    puttygen "$X" -O private-openssh -o "$HOME/.ssh/$TARGET"
    chmod 0644 "$HOME/.ssh/$TARGET.pub"
    chmod 0600 "$HOME/.ssh/$TARGET"
  done;
fi