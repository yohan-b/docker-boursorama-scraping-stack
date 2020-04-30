#!/bin/bash
#Absolute path to this script
SCRIPT=$(readlink -f $0)
#Absolute path this script is in
SCRIPTPATH=$(dirname $SCRIPT)
STACK=$(basename "$SCRIPTPATH")

cat << EOF > /etc/systemd/system/${STACK}.service
[Unit]
Description=Starting ${STACK}
After=network-online.target firewalld.service docker.service docker.socket
Wants=network-online.target docker.service
Requires=docker.socket

[Service]
Type=oneshot
User=$SUDO_USER
ExecStart=$SCRIPTPATH/start.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ${STACK}.service
