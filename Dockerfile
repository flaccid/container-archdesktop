FROM archlinux/archlinux:base-devel AS builder
ARG user=build
RUN pacman -Syu --needed --noconfirm git && \
	useradd --system --no-create-home --shell /bin/bash --home-dir /usr/src $user && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user && \
	chown build /usr/src
USER "$user"
WORKDIR /usr/src
RUN git clone https://aur.archlinux.org/yay.git && \
	cd yay && \
	makepkg -sr --needed --noconfirm && \
	sudo pacman -U --noconfirm yay*.pkg.tar.zst

FROM archlinux
LABEL maintainer="Chris Fordham <chris@fordham.id.au>"
COPY --from=builder /usr/src/yay/*.pkg.tar.zst /tmp/
COPY entry.sh /usr/local/bin/entry.sh
ARG user=vdi
RUN	pacman -Syu --noconfirm && \
	pacman -U --noconfirm /tmp/yay*.pkg.tar.zst && \
	pacman -S --noconfirm reflector rsync && \
	reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist && \
	pacman -Sy && \
	pacman -S --noconfirm \
		base-devel \
		bind \
		curl \
		iputils \
		nmap \
		wget \
		openssh \
		sudo \
		ark \
		gnome \
		gnome-calculator \
		gnome-characters \
		plasma \
		lxde \
		openbox \
		obconf \
		mate \
		xfce4 \
		lxqt \
		icewm \
		cinnamon \
		chromium \
		firefox \
		vivaldi \
		libreoffice-still \
		nautilus \
		nano \
		gvim \
		xterm \
		xorg-xclock \
		xorg-xcalc \
		xorg-xauth \
		xorg-xeyes \
		ttf-droid && \
	useradd --system --create-home --shell /bin/bash "$user" && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user && \
	rm -Rf /tmp/*
USER "$user"
RUN yay -S --noconfirm x2goserver joe google-chrome
USER root
VOLUME /etc/ssh
EXPOSE 22/tcp
ENTRYPOINT ["/usr/local/bin/entry.sh"]
