# Build Image for running ESMFold

- Date: Sunday, Dec 3, 2023
- Author: ChuNan Liu
- Email: <chunan.liu@ucl.ac.uk>

Contents:

- [Build Image for running ESMFold](#build-image-for-running-esmfold)
  - [Build Image](#build-image)
  - [Details](#details)
  - [Run Image](#run-image)
    - [Help information](#help-information)
    - [Run ESMFold with fasta file as input](#run-esmfold-with-fasta-file-as-input)
    - [Overwrite entrypoint](#overwrite-entrypoint)
    - [Test GPU](#test-gpu)

---

## Build Image

```shell
docker build -t $USER/esmfold:base -f Dockerfile .
# or
docker build -t $USER/esmfold:run -f Dockerfile.runtime .
```

- `-t $USER/esmfold:base`: tag the image with the name `$USER/esmfold` and the tag `base`.
  - You can omit `$USER` if you like
- `-f Dockerfile`: this version downloads the checkpoint files into the image
- `-f Dockerfile.runtime`: this version does not download the checkpoint files. Users need to mount the checkpoint files into the container at run time.

## Details

This image is based on the [nvidia/cuda:11.3.1-devel-ubuntu20.04](https://hub.docker.com/layers/nvidia/cuda/11.3.1-devel-ubuntu20.04/images/sha256-83c286510046d7bd291c20ec19f4a8ed5995cc8fdfd8f18b58c5330b0cf2b20f?context=explore) image.

You might already have noticed there are some packages installed in the Dockerfile are downloaded using `gdown` which is a python package that downloads files from Google Drive. These files are:

- **openfold.tar.gz**: the official release of OpenFold
  - My modifications: I commented out the flash-attn package from the default environment.yml file because it's not compatible with the latest version of ESM.
- **esm-main.tar.gz**: the official release of ESM.
- **esm2_t36_3B_UR50D.pt** : the pre-trained ESM2 model.
- **esm2_t36_3B_UR50D-contact-regression.pt**: the pre-trained ESM2 model with contact regression.
- **esmfold_3B_v1.pt**: the pre-trained ESMFold model.
Even though the three `.pt` checkpoint files are downloaded upon first run of the container, it's better to have them in the image to avoid downloading them every time the container is run.

The Google Drive folder for the above files are [esmfold](https://drive.google.com/drive/folders/1voN-GketdgO_tGL84DoV0es_87LphuGW?usp=sharing).

If using the `Dockerfile.runtime` file, you need to mount the checkpoint files into the container at run time. To download the checkpoint files, you can run the following command:

```sh
cd /path/to/host/checkpoints

# esm2_t36_3B_UR50D-contact-regression (6.7KB)
gdown --fuzzy -O esm2_t36_3B_UR50D-contact-regression.pt 1lW8CVTSzX8bwLxbM8lAu_qXQkrPZuSxA

# esm2_t36_3B_UR50D (5.3GB)
curl https://dl.fbaipublicfiles.com/fair-esm/models/esm2_t36_3B_UR50D.pt -o esm2_t36_3B_UR50D.pt

# esmfold_3B_v1 (2.6GB)
curl https://dl.fbaipublicfiles.com/fair-esm/models/esmfold_3B_v1.pt -o esmfold_3B_v1.pt
```

Model links are derived from repository [esm](https://github.com/facebookresearch/esm)

## Run Image

The default entrypoint for the image, as specified in the Dockerfile, is

```Dockerfile
ENTRYPOINT ["zsh", "run-esm-fold.sh"]
```

content of `run-esm-fold.sh`:

```shell
#!/bin/zsh

# init conda
source $HOME/.zshrc

# activate py39-esmfold
conda activate py39-esmfold

# run esm-fold
esm-fold $@
```

### Help information

Run the following command to see the help information of `esm-fold`:

```shell
docker run --rm esmfold:base --help
```

stdout:

```shell
usage: esm-fold [-h] -i FASTA -o PDB [-m MODEL_DIR]
                [--num-recycles NUM_RECYCLES]
                [--max-tokens-per-batch MAX_TOKENS_PER_BATCH]
                [--chunk-size CHUNK_SIZE] [--cpu-only] [--cpu-offload]

optional arguments:
  -h, --help            show this help message and exit
  -i FASTA, --fasta FASTA
                        Path to input FASTA file
  -o PDB, --pdb PDB     Path to output PDB directory
  -m MODEL_DIR, --model-dir MODEL_DIR
                        Parent path to the pre-trained ESM data directory.
  --num-recycles NUM_RECYCLES
                        Number of recycles to run. Defaults to number used in
                        training (4).
  --max-tokens-per-batch MAX_TOKENS_PER_BATCH
                        Maximum number of tokens per gpu forward-pass. This
                        will group shorter sequences together for batched
                        prediction. Lowering this can help with out of memory
                        issues, if these occur on short sequences.
  --chunk-size CHUNK_SIZE
                        Chunks axial attention computation to reduce memory
                        usage from O(L^2) to O(L). Equivalent to running a for
                        loop over chunks of of each dimension. Lower values
                        will result in lower memory usage at the cost of
                        speed. Recommended values: 128, 64, 32. Default: None.
  --cpu-only            CPU only
  --cpu-offload         Enable CPU offloading
```

### Run ESMFold with fasta file as input

If GPUs are available.

```sh
mkdir -p ./example/{input,output,logs}
docker run --rm --gpus all \
  -v ./example/input:/home/vscode/input \
  -v ./example/output:/home/vscode/output \
  esmfold:base \
  -i /home/vscode/input/1a2y-HLC.fasta \
  -o /home/vscode/output \
  > ./example/logs/pred.log 2>./example/logs/pred.err

# if use Dockerfile.runtime
docker run --rm --gpus all \
  -v ./example/input:/home/vscode/input \
  -v ./example/output:/home/vscode/output \
  -v /path/to/host/checkpoints:/home/vscode/.cache/torch/hub/checkpoints \
  esmfold:base \
  -i /home/vscode/input/1a2y-HLC.fasta \
  -o /home/vscode/output \
  > ./example/logs/pred.log 2>./example/logs/pred.err
```

If no GPUs are available, add the `--cpu-only` flag:

```sh
mkdir -p ./example/{input,output,logs}
docker run --rm \
  -v ./example/input:/home/vscode/input \
  -v ./example/output:/home/vscode/output \
  esmfold:base \
  --cpu-only \
  -i /home/vscode/input/1a2y-HLC.fasta \
  -o /home/vscode/output \
  > ./example/logs/pred.log 2>./example/logs/pred.err

# if use Dockerfile.runtime, remember to mount the checkpoint files
# -v /path/to/host/checkpoints:/home/vscode/.cache/torch/hub/checkpoints
```

- `-i /input/1a2y-HLC.fasta`: input fasta file
- `-o /output`: path to output predicted structure
- `> ./example/logs/pred.log 2>./example/logs/pred.err`: redirect stdout and stderr to log files

Other ESMFold flags, refer to [ESMFold repo documentation section](https://github.com/facebookresearch/esm?tab=readme-ov-file#esmfold-structure-prediction-)

- `--num-recycles NUM_RECYCLES`: Number of recycles to run. Defaults to number used in training (default is 4).
- `--max-tokens-per-batch MAX_TOKENS_PER_BATCH`: Maximum number of tokens per gpu forward-pass. This will group shorter sequences together for batched prediction. Lowering this can help with out of memory issues, if these occur on short sequences.
- `--chunk-size CHUNK_SIZE`: Chunks axial attention computation to reduce memory usage from O(L^2) to O(L). Equivalent to running a for loop over chunks of of each dimension. Lower values will result in lower memory usage at the cost of speed. Recommended values: 128, 64, 32. Default: None.
- `--cpu-only`: CPU only
- `--cpu-offload`: Enable CPU offloading

### Overwrite entrypoint

If you want to overwrite the entrypoint, you can do so by adding the following to the end of the `docker run` command:

```sh
docker run --rm --gpus all --entrypoint "/bin/zsh" esmfold:base -c "echo 'hello world'"
```

### Test GPU

```sh
docker run --rm --gpus all --entrypoint "nvidia-smi" esmfold:base
```
