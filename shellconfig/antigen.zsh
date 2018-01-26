# .zshrc Source Basic
source $HOME/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use zimfw/zimfw

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle history
antigen bundle command-not-found

# Theme
DEFAULT_USER=$USER
POWERLEVEL9K_INSTALLATION_PATH=$ANTIGEN_BUNDLES/bhilburn/powerlevel9k
antigen theme bhilburn/powerlevel9k powerlevel9k

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-completions src
antigen bundle zsh-users/zsh-syntax-highlighting

# Tell antigen that you're done.
antigen apply
