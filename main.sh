#!/bin/bash

######################################################################
# init checks
######################################################################

if [[ $(id -u) -ne 0 ]]; then
  echo "WSL main.sh must be run as root"
  exit
fi

######################################################################
# Functions
######################################################################

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
  local VAR_DEFAULT=${!VAR_NAME-${!VAR_DEFAULT_NAME}}
  read -p "What is your $VAR_DESCRIPTION [default: $VAR_DEFAULT]? " VAR
  if [[ -z "$VAR" ]]; then VAR="$VAR_DEFAULT"; fi
  eval "$VAR_DEFAULT_NAME=\"$VAR\""
  eval "$VAR_NAME=\"$VAR\""
}

######################################################################
# Run as root
######################################################################

SRC="$(dirname $(realpath $0))"
USR=${SUDO_USER-${USER}}

# Create the required directories and files
mkdir -p -v $HOME/.config $HOME/.ssh
touch $HOME/.gitconfig

# Assure default configuration is loaded and user configuration exists
source "$SRC/installconfig/config.default.zsh"
if [[ -f "$HOME/.config/config.user.zsh" ]]; then
  source "$HOME/.config/config.user.zsh"
else
  cp -v "$SRC/installconfig/config.default.zsh" "$HOME/.config/config.user.zsh"
fi

request_variable "SSH_KEYS" "directory where putty ssh keys are located"
request_variable "GIT_USER" "git username"
request_variable "GIT_MAIL" "git e-mail"

# Release upgrade
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

echo "#User specified overrides for WSL configuration" > $HOME/.config/config.user.zsh
for i in ${!DEFAULT_*}; do
  echo "${i:8}=\"${!i}\"" >> $HOME/.config/config.user.zsh
done

# Install or update antigen
if [[ ! -d $HOME/.antigen ]]; then
  git clone https://github.com/zsh-users/antigen.git $HOME/.antigen
else
  git -C $HOME/.antigen pull
fi

# Copy config files
cp -v -R "$SRC/shellconfig/"* "$HOME/.config/"

# Fix ownership and permissions on all script linked to provisioning in user directory
chown -R $USR:$USR "$HOME/.zshrc" "$HOME/.profile" "$HOME/.antigen" "$HOME/.config" "$HOME/.ssh" "$HOME/.gitconfig"
chmod -R go-w "$HOME/.zshrc" "$HOME/.profile" "$HOME/.antigen" "$HOME/.config" "$HOME/.ssh" "$HOME/.gitconfig"

# Change config-files
add_config_line "$HOME/.profile" 'umask 002'
add_config_line "$HOME/.profile" 'if test -t 1; then exec zsh; fi'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/antigen.zsh"'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/aliasloading.zsh"'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/sshkeys.zsh"'
add_config_line "$HOME/.zshrc" 'source "$HOME/.config/config.user.zsh"'

# Configure git
git config --global user.email "$GIT_MAIL"
git config --global user.name "$GIT_USER"
git config --global push.default current
git config --global core.autocrlf false
git config --global core.filemode false

# Update antigen
sudo -u $USR zsh -i -c 'antigen update'
sudo -u $USR zsh -i -c 'antigen cache-gen'

# Final text
echo "You might need to restart your shell for all changes to have an impact"
