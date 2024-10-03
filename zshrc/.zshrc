# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/amar/.zshrc'

fpath=(${ASDF_DIR}/completions $fpath)

autoload -Uz compinit
compinit
# End of lines added by compinstall
eval "$(starship init zsh)"

export PATH=$PATH:/home/amar/dev/bin

. "$HOME/.asdf/asdf.sh"
