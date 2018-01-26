#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
  echo "WSL main.sh must be run as root"
  exit
fi

function add_config_line {
  local ACL_FILE="$1"
  local ACL_LINE="$2"
  local ACL_REGEX="$(echo "$ACL_LINE" | sed -E 's/([.*\/])/\\\1/g')"

  if [[ -f "$ACL_FILE" ]]; then
    sed -i "/$ACL_REGEX/d" "$ACL_FILE"
  fi
  echo "$ACL_LINE" >> "$ACL_FILE"
}

# Release upgrade
# apt-mark hold procps strace sudo bash
apt-mark hold bash
add_config_line "/etc/update-manager/release-upgrades" 'Prompt=normal'
RELEASE_UPGRADER_NO_SCREEN=1 do-release-upgrade

# Locale fix
gunzip --keep /usr/share/i18n/charmaps/UTF-8.gz
dpkg-reconfigure --frontend=noninteractive locales

# Configure repo availability for git(-lfs)
add-apt-repository ppa:git-core/ppa -y
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

# Install packages
apt-get update
apt-get install -y \
  putty-tools \
  aptitude \
  git-core \
  git-lfs \
  zsh \
  git

# Maintenance of existing packages
apt-get upgrade -y
apt-get autoremove -y

# Install or update antigen
if [[ ! -d $HOME/.antigen ]]; then
  git clone https://github.com/zsh-users/antigen.git $HOME/.antigen
else
  git -C $HOME/.antigen pull
fi

# Change config-files
add_config_line "$HOME/.profile" 'if test -t 1; then exec zsh; fi'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/antigen.zsh"'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/aliasloading.zsh"'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/sshkeys.zsh"'

# Copy config files
mkdir -p -v $HOME/.config
cp -v -R ./shellconfig/* $HOME/.config

# Fix ownership
chown -R $SUDO_USER:$SUDO_USER "$HOME/.zshrc" "$HOME/.profile" "$HOME/.antigen" "$HOME/.config"
chmod -R go-w "$HOME/.zshrc" "$HOME/.profile" "$HOME/.antigen" "$HOME/.config"

# Configure git
git config --global user.email "supmagc@gmail.com"
git config --global user.name "Jelle Voet"
git config --global push.default current
git config --global core.autocrlf false
git config --global core.filemode false

# Switch to zsh
zsh

# Update antigen
antigen update
antigen cache-gen
