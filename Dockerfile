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
RUN pacman -Syu --noconfirm && \
	pacman -U --noconfirm /tmp/yay*.pkg.tar.zst && \
 	pacman -S --noconfirm \
 		base-devel \
 		bind \
 		curl \
 		iputils \
 		nmap \
 		wget \
 		openssh \
 		sudo \
 		plasma \
 		openbox \
 		xterm \
 		xorg-xclock \
 		xorg-xcalc \
 		xorg-xauth \
 		xorg-xeyes \
 		ttf-droid && \
 	useradd --system --create-home --shell /bin/bash "$user" && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER "$user"
RUN yay -S --noconfirm x2goserver
USER root
ENTRYPOINT ["/usr/local/bin/entry.sh"]
