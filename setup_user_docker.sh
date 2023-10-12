#!/bin/bash
DOCKERD_CONFIG_DIR=/etc/docker/$USER
DOCKERD_SERVICE=/etc/systemd/system/docker-$USER.service
DOCKER_SOCKET=/var/run/docker-$USER.sock
RND_OCTET=$((16#$(echo -n $USER | md5sum | awk '{print $1}' | cut -c 1-2)))
USER_BIP="172.$RND_OCTET.0.1/16"

# Check if DOCKER_HOST is correctly set
if [[ "$DOCKER_HOST" != "unix:///var/run/docker-$USER.sock" ]]; then
    echo "ERROR: The DOCKER_HOST environment variable is not set correctly."
    echo "Please make sure to source your $RC_FILE or restart your shell."
    echo
    echo "Add the following line to your .bashrc/.zshrc:"
    echo "export DOCKER_HOST=unix:///var/run/docker-$USER.sock"
    echo
    echo "Or add the following line to your fish config:"
    echo "set -x DOCKER_HOST unix:///var/run/docker-$USER.sock"
    echo
    echo "After that source your rc file, then check the value using: echo \$DOCKER_HOST"
    echo "Expected value: unix:///var/run/docker-$USER.sock"
    exit 1
fi

# Remove existing user specific docker files
echo "Removing existing user specific docker files..."
sudo systemctl stop docker-$USER &>/dev/null
sudo rm -rf /var/lib/docker-$USER
sudo rm -f $DOCKERD_CONFIG_DIR/daemon.json
sudo rm -f $DOCKERD_SERVICE
sudo ip link delete $USER &>/dev/null

# Create the daemon.json file for the user
sudo mkdir -p $DOCKERD_CONFIG_DIR
sudo bash -c "cat > $DOCKERD_CONFIG_DIR/daemon.json" <<EOF
{
  "userns-remap": "$USER",
  "data-root": "/var/lib/docker-$USER",
  "bridge": "$USER"
}
EOF

# Create the systemd service file for the user's Docker daemon
sudo bash -c "cat > $DOCKERD_SERVICE" <<EOF
[Unit]
Description=Docker Daemon for $USER
After=network.target docker.socket
Requires=docker.socket

[Service]
ExecStart=/usr/sbin/dockerd -H unix:///var/run/docker-$USER.sock --config-file $DOCKERD_CONFIG_DIR/daemon.json --pidfile /var/run/docker-$USER.pid

[Install]
WantedBy=multi-user.target
EOF

# Create bridge for the user docker instance
sudo ip link add name $USER type bridge
sudo ip link set up dev $USER
sudo ip addr add $USER_BIP dev $USER

# Restart the Docker daemon for the user
sudo systemctl enable docker-$USER
sudo systemctl restart docker-$USER
sleep 3
echo "---> Docker configuration and daemon set up for $USER"

# Check the status of the Docker daemon for the user
status=$(sudo systemctl is-active docker-$USER)
if [ "$status" = "active" ]; then
    echo "---> Docker daemon for $USER is running."
else
    echo "---> Failed to start Docker daemon for $USER."
    exit 1
fi

# Test Docker by running a container
container_id=$(DOCKER_HOST="unix://$DOCKER_SOCKET" docker run -d hello-world)
sleep 3
container_status=$(DOCKER_HOST="unix://$DOCKER_SOCKET" docker ps -aq --filter "id=$container_id")
if [ -n "$container_status" ]; then
    docker rm -f $container_id
    echo "---> Hello-World Container removed."
    docker rmi hello-world
    echo "---> Hello-World Image removed."
    echo "---> Docker is working correctly for $USER."
else
    echo "---> Failed to run container for $USER."
    exit 1
fi
