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
COPY entry.sh /usr/local/bin/entry.sh
ARG user=vdi
RUN pacman -Syu --noconfirm && \
	pacman -U --noconfirm /tmp/*.pkg.tar.zst && \
	pacman -S --noconfirm base-devel bind curl iputils nmap wget openssh sudo systemd-sysvcompat && \
	#pacman -S --noconfirm base-devel bind curl iputils nmap wget openssh sudo systemd-sysvcompat gnome && \
	useradd --system --create-home --shell /bin/bash "$user" && \
	echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user && \
	cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done; \
	rm -f /lib/systemd/system/multi-user.target.wants/* \
	rm -f /etc/systemd/system/*.wants/* \
	rm -f /lib/systemd/system/local-fs.target.wants/* \
	rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
	rm -f /lib/systemd/system/basic.target.wants/* \
	rm -f /lib/systemd/system/anaconda.target.wants/* \
	rm -Rfv /tmp/*
VOLUME ["/sys/fs/cgroup"]
ENTRYPOINT ["/usr/local/bin/entry.sh"]
CMD ["/sbin/init"]