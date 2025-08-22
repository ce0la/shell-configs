#/bin/bash

if [[ -f $HOME/.zshrc ]]; then
  diff configs/zshrc $HOME/.zshrc | tee -a zsh_diff_history.log
  cp $HOME/.zshrc $HOME/.zshrc_old
  cp configs/zshrc $HOME/.zshrc
fi

if [[ -f $HOME/.vimrc ]]; then
  diff configs/vimrc $HOME/.vimrc | tee -a vim_diff_history.log
  cp $HOME/.vimrc $HOME/.vimrc_old
  cp configs/vimrc $HOME/.vimrc
fi
