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

function request_variable {
  local VAR_NAME="$1"
  local VAR_DEFAULT_NAME="DEFAULT_$VAR_NAME"
  local VAR_DESCRIPTION="$2"
  read -p "What is your $VAR_DESCRIPTION [default: ${!VAR_DEFAULT_NAME}]? " VAR
  if [[ -z "$VAR" ]]; then VAR="${!VAR_DEFAULT_NAME}"; fi
  eval "$VAR_DEFAULT_NAME=\"$VAR\""
  eval "$VAR_NAME=\"$VAR\""
}

source "$HOME/.config/config.default.zsh"
request_variable "SSH_KEYS" "directory where putty ssh keys are located"

echo "#User specified overrides for WSL configuration" > ~/.config/config.user.zsh
for i in ${!DEFAULT_*}; do
  echo "$i=\"${!i}\"" >> ~/.config/config.user.zsh
done

# Release upgrade
# apt-mark hold procps strace sudo bash
apt-mark hold bash
sed -i "/Prompt.*$/d" "/etc/update-manager/release-upgrades"
echo "Prompt=normal" >> "/etc/update-manager/release-upgrades"
RELEASE_UPGRADER_NO_SCREEN=1 do-release-upgrade

# Locale fix
gunzip --keep --force /usr/share/i18n/charmaps/UTF-8.gz
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
add_config_line "$HOME/.config/config.user.zsh" 'source "$HOME/.config/config.user.zsh"'

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
