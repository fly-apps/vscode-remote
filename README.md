# VS Code Remote

This image runs a SSH daemon and exposes that port through fly.

## Setup

### Create an app

```bash
flyctl apps create
```

### One-time setup

Run this little script to generate a fly.toml:

```bash
./generate_fly_toml
```

Create a volume

```bash
flyctl volumes create data --region ewr --size 20
```

_Note: make sure you use the region where your app was created for less surprises_

## Deploy

flyctl deploy --build-arg USER=$(whoami)

### `--build-arg`s

#### USER

Specify which user to create inside your VM when you're SSHing in.

#### USE_DOCKER=y

Appending `--build-arg USE_DOCKER=y` to the deploy command flags will setup docker inside your VM. It will also automatically start Docker on boot as a service and use your mount for storage.

#### EXTRA_PKGS

Using `--build-arg EXTRA_PKGS=` with a list of apt packages you'd like built into your image is a great way to add dependencies. For example:

```
flyctl deploy --build-arg USER=$(whoami) --build-arg EXTRA_PKGS="make cmake llvm lld clang zsh htop"
```