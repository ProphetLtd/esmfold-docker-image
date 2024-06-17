#!/bin/zsh

if [ $# -lt 2 ]; then
  echo "Usage: $0 <predict|train> <additional parameters>"
  exit 1
fi

# activate py39-esmfold
source $HOME/.zshrc
conda activate py39-esmfold

command=$1

# Shift the parameters so that $@ contains only the additional parameters
shift

if [[ "$command" == "predict" ]]; then
  python /home/vscode/alphaflow/predict.py "$@"
elif [[ "$command" == "train" ]]; then
  python /home/vscode/alphaflow/train.py "$@"
else
  echo "Unknown command: $command"
  echo "Usage: $0 <predict|train> <additional parameters>"
  exit 1
fi