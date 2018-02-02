# WSL Provisioning

These script provision and maintain your WSL installation. They offer the following functionalities:

- zsh as default shell
- antigen installation based on zim
- release update of your installation
- import and conversion of putty keys
- install powerlevel9k theme

## Installation

```shell
git clone git@github.com:supmagc/provision-wsl.git
sudo ./provision-wsl/main.sh
```

## Upgrade

```shell
git -C provision-wsl pull
sudo ./provision-wsl/main.sh
```
