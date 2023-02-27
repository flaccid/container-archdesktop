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
	makepkg -sr --needed --noconfirm

FROM archlinux
LABEL maintainer="Chris Fordham <chris@fordham.id.au>"
COPY --from=builder /usr/src/yay/*.pkg.tar.zst /tmp/
ARG user=vdi
RUN pacman -Syu --noconfirm && \
	pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
	pacman -S --noconfirm curl wget openssh sudo systemd && \
	useradd --system --no-create-home --shell /bin/bash --home-dir /usr/src $user && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user && \
	#yay -S --noconfirm x2goserver && \
	rm -Rfv /tmp/*
CMD ["/sbin/init", "--user"]