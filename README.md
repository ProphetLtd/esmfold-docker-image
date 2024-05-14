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

## Docker Hub

You can pull images from the docker hub page at: https://hub.docker.com/r/biochunan/esmfold-image
<a href=https://github.com/biochunan/esmfold-docker-image/assets/29458139/9fa95a57-eabf-45ab-ab12-45ae2c3a47ce><img src="https://github.com/biochunan/esmfold-docker-image/assets/29458139/9fa95a57-eabf-45ab-ab12-45ae2c3a47ce" width=500 alt="dockerhub-page-screenshot"></a>

## Build Image

Use Dockerfiles provided in `./Dockerfiles` to build desired images.

The following are provided in the script `./build-image.sh`:

```shell
# build image, add non-root user
docker build --no-cache -t $USER/esmfold:nonroot-devel -f Dockerfiles/Dockerfile.nonroot .

# build runtime image, add non-root user
docker build --no-cache -t $USER/esmfold:nonroot-runtime -f Dockerfiles/Dockerfile.nonroot.runtime .

# build image, root user only
docker build --no-cache -t $USER/esmfold:root-devel -f Dockerfiles/Dockerfile.root .

# build runtime image, root user only
docker build --no-cache -t $USER/esmfold:root-runtime -f Dockerfiles/Dockerfile.root.runtime .
```

- `-t $USER/esmfold:root-devel`: tag images
  - `$USER`: your username
  - `esmfold`: image name
  - `root-devel`: image tag, see below for details
    - `root`/`non-root`: the image runs as `root`, or a non-root user (`vscode` with `USER_UID` and `USER_GID` both set to `1000`).
    - `devel`/`runtime`: the image includes model checkpoints and the model itself if `devel`, or not if `runtime` meaning checkpoints need to be mounted at runtime.

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

Example scripts are provdied in `./example/scripts` to run ESMFold with the built image.

**NOTICE**: these scripts assume your current working directory is the root of the repository.

The default entrypoint for the image, as specified in the Dockerfile, is

```Dockerfile
ENTRYPOINT ["zsh", "run-esm-fold.sh"]
```

<!-- insert a foldable element -->
<details>

<summary>content of `run-esm-fold.sh`:</summary>

```shell
#!/bin/zsh

# init conda
source $HOME/.zshrc

# activate py39-esmfold
conda activate py39-esmfold

# run esm-fold
esm-fold $@
```
</details>

### Help information

Run the following command to see the help information of `esm-fold`:

```shell
docker run --rm $USER/esmfold:root-devel --help
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
cd /path/to/esmfold-docker-image  # root of the repository

mkdir -p ./example/{input,output,logs}

########################
#      run as root     #
########################
# if use devel, checkpoints are already in the image
docker run --rm --gpus all \
-v ./example/input:/root/input \
-v ./example/output:/root/output \
esmfold:root-devel \
-i /root/input/1a2y-HLC.fasta \
-o /root/output \
> ./example/logs/pred-root-devel.log 2>./example/logs/pred-root-devel.err

# if use runtime, mount the checkpoints on the host machine, e.g. 
trainModelsDir=/mnt/Data/trained_models/ESM2
docker run --rm --gpus all \
-v ./example/input:/root/input \
-v ./example/output:/root/output \
-v $trainModelsDir:/root/.cache/torch/hub/checkpoints \
esmfold:root-runtime \
-i /root/input/1a2y-HLC.fasta \
-o /root/output \
> ./example/logs/pred-root-devel.log 2>./example/logs/pred-root-devel.err

########################
# run as non-root user #
########################
# non-root user `vscode` with userID:groupID=1000:1000
# if use devel, checkpoints are already in the image
docker run --rm --gpus all \
-v ./example/input:/home/vscode/input \
-v ./example/output:/home/vscode/output \
esmfold:nonroot-devel \
-i /home/vscode/input/1a2y-HLC.fasta \
-o /home/vscode/output \
> ./example/logs/pred.log 2>./example/logs/pred.err

# if use runtime, checkpoints need to be mounted
docker run --rm --gpus all \
-v ./example/input:/home/vscode/input \
-v ./example/output:/home/vscode/output \
-v /path/to/host/checkpoints:/home/vscode/.cache/torch/hub/checkpoints \
esmfold:nonroot-runtime \
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
esmfold:nonroot-devel \
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
docker run --rm --gpus all --entrypoint "/bin/zsh" $USER/esmfold:nonroot-devel -c "echo 'hello world'"
```

### Test GPU

```sh
docker run --rm --gpus all --entrypoint "nvidia-smi" $USER/esmfold:nonroot-devel
```

##  Dockerhub

The image is also available on Dockerhub: [biochunan/esmfold-image](https://hub.docker.com/r/biochunan/esmfold-image/tags)
