#!/bin/bash
USERNAME=$USER
DOCKERD_CONFIG_DIR=/etc/docker/$USERNAME
DOCKERD_SERVICE=/etc/systemd/system/docker-$USERNAME.service

# Create the Docker configuration directory for the user
sudo mkdir -p $DOCKERD_CONFIG_DIR

# Create the daemon.json file for the user
sudo bash -c "cat > $DOCKERD_CONFIG_DIR/daemon.json" <<EOF
{
    "userns-remap": "$USERNAME",
    "data-root": "/var/lib/docker-$USERNAME"
}
EOF

# Create the systemd service file for the user's Docker daemon
sudo bash -c "cat > $DOCKERD_SERVICE" <<EOF
[Unit]
Description=Docker Daemon for $USERNAME
After=network.target docker.socket
Requires=docker.socket

[Service]
ExecStart=/usr/sbin/dockerd -H unix:///var/run/docker-$USERNAME.sock --config-file $DOCKERD_CONFIG_DIR/daemon.json --pidfile /var/run/docker-$USERNAME.pid

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Docker daemon for the user
sudo systemctl daemon-reload
sudo systemctl enable docker-$USERNAME
sudo systemctl start docker-$USERNAME

echo "Docker configuration and daemon set up for $USERNAME"

# Restart the Docker daemon for the user
sudo systemctl restart docker-$USERNAME

# Wait for the Docker daemon to start
sleep 3

# Check the status of the Docker daemon for the user
status=$(sudo systemctl is-active docker-$USERNAME)

if [ "$status" = "active" ]; then
    echo "Docker daemon for $USERNAME is running."
else
    echo "Failed to start Docker daemon for $USERNAME."
    exit 1
fi

# Test Docker by running a container
container_id=$(docker run -d hello-world)

# Wait for the container to start
sleep 3

# Check the status of the container
container_status=$(docker ps -aq --filter "id=$container_id")

if [ -n "$container_status" ]; then
    # Remove the hello world container
    docker rm -f $container_id
    echo "Hello-World Container removed."
    # Remove the hello-world image
    docker rmi hello-world
    echo "Hello-World Image removed."
    echo "Docker is working correctly for $USERNAME."
else
    echo "Failed to run container for $USERNAME."
    exit 1
fi

