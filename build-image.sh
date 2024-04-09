#!/bin/zsh

WD=$(pwd)

# Build the image
docker build -t $USER/esmfold:base .
