#!/bin/bash
# tsn userdata for host

# Update system
yum update -y
logger -p user.notice "BOOTSTRAP: Updating system - $?"

# Installing Docker
yum install -y docker
logger -p user.notice "BOOTSTRAP: Installing Docker - $?"

# Installing Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
logger -p user.notice "BOOTSTRAP: Installing Docker Compose - $?"

# Starting Docker
/etc/init.d/docker start
logger -p user.notice "BOOTSTRAP: Starting Docker Daemon - $?"

# Writing docker-compose.yml
mkdir -p /tmp/qsalary
cat > /tmp/qsalary/docker-compose.yml <<EOF
version: "3.4"

services:
	qsalary:
		build: .
		image: qsalary:latest
		command: "qsalary.sh YEAR serve"
EOF

logger -p user.notice "BOOTSTRAP: Writing docker-compose.yml - $?"

# Run application
sleep 60
cd /tmp/qsalary
screen -d -m /usr/local/bin/docker-compose --project-directory /tmp/qsalary/ up
logger -p user.notice "BOOTSTRAP: Application Started - $?"
