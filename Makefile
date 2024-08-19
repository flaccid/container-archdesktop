DOCKER_REGISTRY = index.docker.io
IMAGE_NAME = archdesktop
IMAGE_VERSION = latest
IMAGE_ORG = flaccid
IMAGE_TAG = $(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):$(IMAGE_VERSION)
KUBE_NAMESPACE = default

WORKING_DIR := $(shell pwd)

.DEFAULT_GOAL := help

.PHONY: build

docker-release:: docker-build docker-push ## Builds and pushes the docker image to the registry

docker-push:: ## Pushes the docker image to the registry
		@docker push $(IMAGE_TAG)

docker-build:: ## builds the docker image locally
		@docker build  \
			--pull \
			-t $(IMAGE_TAG) \
				$(WORKING_DIR)

docker-build-systemd:: ## builds the docker image locally (systemd version)
		@docker build  \
			--file Dockerfile.systemd \
			-t $(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):systemd \
				$(WORKING_DIR)

docker-build-systemd-pull:: ## builds the docker image locally with pre-pull (systemd version)
		@docker build  \
			--pull \
			--file Dockerfile.systemd \
			-t $(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):systemd \
				$(WORKING_DIR)

docker-build-clean:: ## cleanly builds the docker image locally
		@docker build  \
			--no-cache \
			--pull \
			-t $(IMAGE_TAG) \
				$(WORKING_DIR)

docker-run:: ## Runs the docker image
		docker run \
			--name archdesktop \
			-it \
			--cap-add=SYS_ADMIN \
			--device /dev/fuse \
			--privileged \
			--tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
			-e VDI_PASSWORD=vdi \
				$(IMAGE_TAG)

docker-run-chrome:: ## runs the docker image (chrome desktop mode)
		docker run \
			--name archdesktop \
    		-e DISPLAY=${DISPLAY} \
    		-v /tmp/.X11-unix:/tmp/.X11-unix \
    		-v ${HOME}/.Xauthority:/root/.Xauthority \
			-v /sys:/sys \
			-v /run/user/$(shell id -u):/run/user/host \
			-v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket \
    		--net=host \
			--privileged \
			-it \
			--rm \
			-e VDI_PASSWORD=vdi \
			-e DESKTOP_MODE=chrome \
				$(IMAGE_TAG)

docker-run-chrome-host:: ## runs the docker image (chrome desktop mode w/ host profile)
		docker run \
			--name archdesktop \
    		-e DISPLAY=${DISPLAY} \
    		-v /tmp/.X11-unix:/tmp/.X11-unix \
    		-v ${HOME}/.Xauthority:/root/.Xauthority \
			-v ${HOME}/.config/google-chrome:/root/.config/google-chrome \
			-v /sys:/sys \
			-v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket \
			-v /run/user/89377:/run/user/89377 \
    		--net=host \
			--privileged \
			-it \
			--rm \
			-e VDI_PASSWORD=vdi \
			-e DESKTOP_MODE=chrome \
				$(IMAGE_TAG)

docker-run-systemd:: ## Runs the docker image (systemd version)
		docker run \
			--name archdesktop \
			-it \
			--privileged \
			--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
			-e VDI_PASSWORD=vdi \
				$(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):systemd

docker-exec-shell:: ## Executes a shell in running container
		@docker exec \
			-it \
				archdesktop /bin/bash

docker-run-shell:: ## Runs the docker image with bash as entrypoint
		@docker run \
			-it \
			--entrypoint /bin/bash \
				$(IMAGE_TAG)

docker-rm:: ## Removes the running docker container
		@docker rm -f archdesktop

docker-test:: ## tests the runtime of the docker image in a basic sense
		@docker run $(IMAGE_TAG) archdesktop --version

helm-install:: ## installs using helm from chart in repo
		@helm install \
			-f values.yaml \
			--namespace $(KUBE_NAMESPACE) \
				archdesktop charts/archdesktop

helm-upgrade:: ## upgrades deployed helm release
		@helm upgrade \
			-f values.yaml \
			--namespace $(KUBE_NAMESPACE) \
				archdesktop charts/archdesktop

helm-uninstall:: ## deletes and purges deployed helm release
		@helm uninstall \
			--namespace $(KUBE_NAMESPACE) \
				archdesktop

helm-reinstall:: helm-uninstall helm-install ## Uninstalls the helm release, then installs it again

helm-render:: ## prints out the rendered chart
		@helm install \
			-f values.yaml \
			--namespace $(KUBE_NAMESPACE) \
			--dry-run \
			--debug \
				archdesktop charts/archdesktop

helm-validate:: ## runs a lint on the helm chart
		@helm lint \
			-f values.yaml \
			--namespace $(KUBE_NAMESPACE) \
				charts/archdesktop

helm-package:: ## packages the helm chart into an archive
		@helm package charts/archdesktop

helm-index:: ## creates/updates the helm repo index file
		@helm repo index --url https://flaccid.github.io/container-archdesktop/ .

helm-flush:: ## removes local helm packages and index file
		@rm -f ./pritunl-*.tgz
		@rm -f index.yaml

# A help target including self-documenting targets (see the awk statement)
define HELP_TEXT
Usage: make [TARGET]... [MAKEVAR1=SOMETHING]...

Available targets:
endef
export HELP_TEXT
help: ## This help target
	@cat .banner
	@echo
	@echo "$$HELP_TEXT"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "\033[36m%-30s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
