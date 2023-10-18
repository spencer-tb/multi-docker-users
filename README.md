# Multi Docker Users

This repository contains multiple Ansible playbooks for managing multiple users within the hive simulation server.

It allows for multiple users to use there own isolated Docker instance, as opposed to sharing one instance between multiple users avoiding a multitude of conflicts.

We are required to do this to run separate [hive](https://github.com/ethereum/hive) instances per user on our server.
Hive uses docker containers for each of its simulations hence we may disrupt another users simulation if we are sharing a docker instance.

## Usage

As we are using Ansible, alterations to users on the server must be changed by running the playbooks locally.

### Setting up for Ansible

After cloning the repo locally, install Ansible (and Python):

On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install python3 python3-pip
pip3 install ansible
ansible --version
```

On MacOS:

```bash
brew install python
brew update
brew install ansible
ansible --version
```

Create an inventory file, for access to the server:

```bash
git clone git@github.com:spencer-tb/multi-docker-users.git
cd multi-docker-users
echo -e "[all]\n<SERVER_IP> ansible_ssh_user=<ROOT_USER>" > inventory.ini
```

Replace "SERVER_IP" with the IP address of the server and "ROOT_USER" with a root user that exists within the server.

### Creating a new user

To create a new user on the server we run the `setup_new_user.yml` playbook:

```bash
ansible-playbook -i inventory.ini setup_new_user.yml --extra-vars "username=<NEW_USER>"
```

Upon running the playbook, a prompt for the user password and ssh public key will appear. These are required for access to the newly user created on the server.

The entire public key must be added to the prompt like the following below:

```bash
Enter the password for the new user: 
confirm Enter the password for the new user: 
Enter the public SSH key for the new user: ssh-ed25519 AAAAC3NzaC1lZ...tzDLUiXeXHv6BaFQ082lpy hello@hello
```

### Reconfiguring docker for an existing user

If we need to reconfigure docker for an existing user, due to un-forseen changes on the server, we can run run the `config_single_docker_user.yml` playbook:

```bash
ansible-playbook -i inventory.ini config_single_docker_user.yml --extra-vars "username=<NEW_USER>"
```

Note "NEW_USER" must already exist on the server.

Docker data for that user will be deleted, including images, containers, volumes, and network configurations, before reconfiguring.

### Reconfiguring docker all users on the server

If we need to reconfigure docker for all users, we can run run the `config_multi_docker_users.yml` playbook:

```bash
ansible-playbook -i inventory.ini config_multi_docker_users.yml
```

Docker data for all users will be deleted, including images, containers, volumes, and network configurations, before reconfiguring.

### Removing an existing user

If we want to remove an existing user on the server, we can run run the `remove_existing_user.yml` playbook:

```bash
ansible-playbook -i inventory.ini remove_existing_user.yml --extra-vars "username=<EXISTING_USER>"
```

Note "EXISTING_USER" must already exist on the server.

All user related data for will be deleted, including docker related data.

## Playbook Structure

`config_multi_docker_users.yml`, `config_single_docker_user.yml` and `setup_new_user.yml` run all the tasks within `docker_setup_tasks.yml`.

`docker_setup_tasks.yml` utilizes the parameterized files `docker_daemon.json.j2` and `docker_service.j2` within its tasks.

```code
├── config_multi_docker_users.yml
│   └──docker_setup_tasks.yml
│       ├── docker_daemon.json.j2
│       └── docker_service.j2
├── config_single_docker_user.yml
│   └──docker_setup_tasks.yml
│       ├── docker_daemon.json.j2
│       └── docker_service.j2
├── setup_new_user.yml
│   └──docker_setup_tasks.yml
│       ├── docker_daemon.json.j2
│       └── docker_service.j2
└── remove_existing_user.yml
```

The dependence of `docker_setup_tasks.yml`, `docker_daemon.json.j2` and `docker_service.j2` allows for easier maintainability of the playbooks.
