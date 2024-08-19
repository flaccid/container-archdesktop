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

FROM archlinux AS base
ARG user=vdi
COPY --from=builder /usr/src/yay/*.pkg.tar.zst /tmp/
RUN	pacman -Syu --noconfirm && \
	pacman -U --noconfirm /tmp/yay*.pkg.tar.zst && \
	pacman -S --noconfirm reflector rsync && \
	reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist && \
	pacman -Sy && \
	pacman -S --noconfirm \
	ark \
	base-devel \
	bind \
	firefox \
	chromium \
	cinnamon \
	curl \
	gnome \
	gnome-calculator \
	gnome-characters \
	gvim \
	icewm \
	iputils \
	libreoffice-still \
	lxde \
	lxqt \
	mate \
	nano \
	nautilus \
	nmap \
	obconf \
	openbox \
	openssh \
	plasma \
	sudo \
	ttf-droid \
	upower \
	vivaldi \
	wget \
	xfce4 \
	xorg-xauth \
	xorg-xcalc \
	xorg-xclock \
	xorg-xeyes \
	xorg-xhost \
	xterm && \
	useradd --system --create-home --shell /bin/bash "$user" && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user

FROM base AS aur
ARG user=vdi
USER "$user"
RUN yay -S --noconfirm pod2man && \
	yay -S --noconfirm \
	google-chrome \
	joe

FROM aur AS last
ARG user=vdi
USER "$user"
RUN yay -S --noconfirm \
	x2goclient \
	x2goserver && \
	sudo pacman -Scc --noconfirm && \
	sudo rm -Rf /tmp/*

FROM last
ARG user=vdi
ENV VDI_USER=${user}
LABEL maintainer="Chris Fordham <chris@fordham.id.au>"
USER root
COPY entry.sh /usr/local/bin/entry.sh
VOLUME /etc/ssh
EXPOSE 22/tcp
ENTRYPOINT ["/usr/local/bin/entry.sh"]
