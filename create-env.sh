#!/bin/zsh

# init conda
conda init zsh > /dev/null 2>&1

# source .zshrc to activate conda
source $HOME/.zshrc

# install openfold
pushd $HOME/openfold
conda env create -f $HOME/openfold/openfold-venv.yaml \
    && conda activate openfold-venv \
    && pip install . \
    && cd $HOME \
    && rm -rf $HOME/openfold
popd

# ------------------- install esmfold command -------------------
# install esm
conda create -n py39-esmfold --clone openfold-venv \
    && conda activate py39-esmfold

# install esm-fold command
pushd $HOME
tar -zxvf $HOME/esm-main.tar.gz -C $HOME \
    && rm $HOME/esm-main.tar.gz \
    && chown -R $USER:$USER $HOME/esm-main \
    && chmod -R 777 $HOME/esm-main \
    && pushd $HOME/esm-main \
    && conda env update -f $HOME/esm-main/py39-esmfold.yaml \
    && pip install . \
    && popd \
    && rm -rf $HOME/esm-main
popd

# clean up
conda deactivate \
    && conda clean -a -y \
    && pip cache purge
