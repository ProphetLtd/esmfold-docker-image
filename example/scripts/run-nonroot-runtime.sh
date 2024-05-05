#!/bin/zsh

# Set configuration variables
BASE=$(dirname $(realpath $0))
trainModelsDir=/mnt/Data/trained_models/ESM2

pushd $(dirname $(dirname $BASE))  # root directory of the project
docker run --rm --gpus all \
-v ./example/input:/home/vscode/input \
-v ./example/output:/home/vscode/output \
-v $trainModelsDir:/home/vscode/.cache/torch/hub/checkpoints \
chunan/esmfold:nonroot-runtime \
-i /home/vscode/input/1a2y-HLC.fasta \
-o /home/vscode/output/nonroot-runtime \
> ./example/logs/pred-nonroot-runtime.log  2>./example/logs/pred-nonroot-runtime.err