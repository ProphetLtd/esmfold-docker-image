# Notes

- `Dockerfile.nonroot`: includes model checkpoints and the model itself.
- `Dockerfile.root`: same as `Dockerfile.nonroot` but runs as `root`.
- `Dockerfile.runtime.nonroot`: Do not include model checkpoints. The checkpoints can be download separately and mounted to the container at runtime.
- `Dockerfile.runtime.root`: same as `Dockerfile.runtime.nonroot` but runs as `root`.
