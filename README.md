# VS Code Remote

This image runs a SSH daemon and exposes that port through fly.

## Setup

### Create an app

```bash
flyctl apps create
```

### One-time setup

Run this little script to generate SSH keys for the host and for your user:

```bash
./setup
```

Create secrets!

```bash
./create_secrets
```

Create a volume

```bash
flyctl volumes create data --region ewr --size 20
```

_Note: make sure you use the region where your app was created for less surprises_

## Deploy

flyctl deploy --build-arg USER=$(whoami)