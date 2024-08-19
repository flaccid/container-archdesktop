#!/bin/bash -e

if [[ "$SKIP_ENTRY" == "1" ]]; then
	echo 'skipping entrypoint script'
	su - vdi
else
	# echo 'loading fuse kernel module...'
	# modprobe fuse

	if [ -e /mnt/host/home ] && [ ! -z /mnt/host/home ]; then
		! getent group hostusers >/dev/null 2>&1 && echo 'adding group hostusers' && sudo groupadd --gid 2000 hostusers
		echo "%hostusers ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/hostusers" >/dev/null 2>&1
		for d in /mnt/host/home/*/ ; do
			user=$(basename "$d")
			# NOTE: local user and group names have a 32-bit length limit
			user="${user:0:32}"
			uid=$(find "$d" -maxdepth 0 -printf '%u\n')
			gid=$(find "$d" -maxdepth 0 -printf '%g\n')
			echo "user=$user uid=$uid gid=$gid"
			if ! getent group "$user" >/dev/null 2>&1; then
				if [[ "$gid" != "root" ]]; then 
					echo "  adding group $user"
					sudo groupadd --gid "$gid" "$user"
				fi
			fi
			if ! id -u "$user" >/dev/null 2>&1; then
				echo "  adding user $user"
				sudo useradd \
					--shell /bin/bash \
					-d "$d" \
					-u "$uid" \
					-g "$gid" \
						"$user"
			fi
			# add the user to the hostuser's group
			sudo usermod -a -G hostusers "$user"
		done
	fi

	# allow x server access to non-network local connections
	xhost local:

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
	export DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/dbus/system_bus_socket"
	
	/usr/bin/dbus-daemon \
		--system \
		--fork \
		--nopidfile \
		--address="$DBUS_SESSION_BUS_ADDRESS"
	
	echo 'adding system profiles...'
	echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket" > /etc/profile.d/dbus.sh
	echo "export FONTCONFIG_PATH=/etc/fonts" > /etc/profile.d/fonts.sh
	chmod +x -v /etc/profile.d/dbus.sh /etc/profile.d/fonts.sh

	echo 'starting x2gosessions...'
	/usr/sbin/x2gocleansessions

	echo "DISPLAY=$DISPLAY"
	echo "desktop mode: $DESKTOP_MODE"
	echo "---------------------------"

	case "$DESKTOP_MODE" in
		chrome)
			if [[ $UID == 1 ]]; then
				/usr/sbin/google-chrome-stable \
					--no-sandbox \
					--no-default-browser-check \
					--disable-dev-shm-usage \
					--disable-gpu \
						https://onpoint.recipes/
			else
				su -c '/usr/sbin/google-chrome-stable --no-default-browser-check --disable-dev-shm-usage --disable-gpu https://onpoint.recipes/' vdi
			fi
		;;
	*)
			echo 'no valid desktop mode set.'
		;;
	esac
fi
