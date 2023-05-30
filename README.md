# Docker Setup for User

This repository contains a script that automates the setup of an isolated
Docker daemon for a user.

It allows different users to run use there own isolated Docker instances,
as opposed to sharing one instance between multiple users.

We are required to do this, as we are using separate
[hive](https://github.com/ethereum/hive) instances per user.


## Usage
From your user account on the server, follow these instructions.


### Update your bashrc (or equivalent)

Add the following line to your bashrc.
```bash
export DOCKER_HOST=unix:///var/run/docker-$USER.sock
```

Refresh bashrc:
```bash
source .bashrc
```

This forces your docker host to point to your own unique docker socket.


### Run the script

The remaining magic is done within the following script.
```bash
git clone <repository-url>
cd 
chmod +x setup_user_docker.sh
./setup_user_docker.sh
```


