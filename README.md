# Docker Setup for User

This repository contains a script that automates the setup of an isolated
Docker daemon for a user.

It allows different users to use there own isolated Docker instance,
as opposed to sharing one instance between multiple users.

To give you an example, we are required to do this, as we are using separate
[hive](https://github.com/ethereum/hive) instances per user on our server. Hive
uses docker containers for each of its simulations hence we may disrupt another users
simulation if we are sharing a docker instance (daemon).


## Usage

From your user account on the server, follow these instructions.


### New Users

#### Update your bashrc (or equivalent)

Add the following line to your bashrc.
```bash
export DOCKER_HOST=unix:///var/run/docker-$USER.sock
```
Refresh bashrc:
```bash
source .bashrc
```
This forces your docker host to point to your own unique docker socket.


#### Run the script

The remaining magic is done within the following script.
```bash
git clone <repository-url>
cd 
chmod +x setup_user_docker.sh
./setup_user_docker.sh
```

### Resetting Docker

To refresh & reset your docker users docker instance.
```bash
docker system prune -a
```
This will remove all stopped containers and the created user bridge.

Re-run the script:
```bash
./setup_user_docker.sh
```

