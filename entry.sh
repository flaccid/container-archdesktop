#!/bin/bash -e

# echo 'loading fuse kernel module...'
# modprobe fuse

if ! pacman -Q | grep x2goserver; then
	echo 'installing x2goserver...'
	su -c 'yay -S --noconfirm x2goserver' vdi
fi

echo 'initialising x2go db...'
x2godbadmin --createdb

echo 'starting x2gosessions...'
/usr/sbin/x2gocleansessions --debug
