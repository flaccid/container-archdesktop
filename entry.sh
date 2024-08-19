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

if ! [ -e /etc/machine-id ]; then
	systemd-machine-id-setup
fi

echo 'starting dbus-daemon...'
export XDG_RUNTIME_DIR=/run/user/host
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
#export DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/dbus/system_bus_socket"

/usr/bin/dbus-daemon \
	--session \
	--address="$DBUS_SESSION_BUS_ADDRESS" \
	--fork \
	--nopidfile \
	--syslog-only

#/usr/bin/dbus-daemon --system --fork --nopidfile --address="unix:path=/run/dbus/system_bus_socket"
#echo 'adding system profiles...'
#echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket" > /etc/profile.d/dbus.sh
#echo "export FONTCONFIG_PATH=/etc/fonts" > /etc/profile.d/fonts.sh
#chmod +x -v /etc/profile.d/dbus.sh /etc/profile.d/fonts.sh

echo 'starting x2gosessions...'
/usr/sbin/x2gocleansessions

echo "DISPLAY=$DISPLAY"
echo "desktop mode: $DESKTOP_MODE"
echo "---------------------------"

case "$DESKTOP_MODE" in
	chrome)
		/usr/sbin/google-chrome-stable \
			--no-sandbox \
			--no-default-browser-check \
			--disable-dev-shm-usage \
			--disable-gpu \
				https://onpoint.recipes/
      ;;
   *)
		echo 'no valid desktop mode set.'
     ;;
esac

#su - vdi

#echo "> $@" && exec "$@"
