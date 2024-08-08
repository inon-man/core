#!/bin/bash
if [ -d "$HOME/.terra-local" ]; then
  read -p "remove $HOME/.terra-local? (y/n) " answer
  if [ $answer == "y" ]; then
    rm -rfv $HOME/.terra-local/
  fi
fi
