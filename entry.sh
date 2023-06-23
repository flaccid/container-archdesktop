#!/bin/bash -e

# echo 'loading fuse kernel module...'
# modprobe fuse

if ! pacman -Q | grep x2goserver; then
	echo 'installing x2goserver...'
	su -c 'yay -S --noconfirm x2goserver' vdi
fi

echo 'initialising x2go db...'
x2godbadmin --createdb

echo 'generating ssh host keys...'
ssh-keygen -A

[ ! -z "$VDI_PASSWORD" ] && echo 'setting vdi password...' && echo "vdi:$VDI_PASSWORD" | chpasswd

echo 'starting sshd...'
/usr/sbin/sshd -D &

echo 'starting dbus-daemon..'
systemd-machine-id-setup
/usr/bin/dbus-daemon --system --fork --nopidfile --address="unix:path=/run/dbus/socket"
echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/socket" > /etc/profile.d/dbus.sh
chmod +x -v /etc/profile.d/dbus.sh

echo 'starting x2gosessions...'
/usr/sbin/x2gocleansessions --debug
