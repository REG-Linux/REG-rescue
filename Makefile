PROJECT_DIR	:= $(shell pwd)
DL_DIR		?= $(PROJECT_DIR)/dl
OUTPUT_DIR	?= $(PROJECT_DIR)/output
CCACHE_DIR	?= $(PROJECT_DIR)/buildroot-ccache
LOCAL_MK	?= $(PROJECT_DIR)/rescue.mk
EXTRA_OPTS	?=
DOCKER_OPTS	?=
NPROC		:= $(shell nproc)
MAKE_JLEVEL	?= $(NPROC)
MAKE_LLEVEL	?= $(shell echo $$(($(NPROC) * 1)))
BATCH_MODE	?=
PARALLEL_BUILD	?= y
DEBUG_BUILD	?=
DOCKER		?= docker

-include $(LOCAL_MK)

ifdef PARALLEL_BUILD
	EXTRA_OPTS +=  BR2_PER_PACKAGE_DIRECTORIES=y
endif

ifdef DEBUG_BUILD
	EXTRA_OPTS +=  BR2_ENABLE_DEBUG=y
endif

MAKE_OPTS  += -j$(MAKE_JLEVEL)
MAKE_OPTS  += -l$(MAKE_LLEVEL)

ifndef BATCH_MODE
	DOCKER_OPTS += -i
endif

DOCKER_REPO := reglinux
IMAGE_NAME  := reglinux-build

TARGETS := $(sort $(shell find $(PROJECT_DIR)/configs/ -name 'r*' | sed -n 's/.*\/rescue-\(.*\).board/\1/p'))
UID  := $(shell id -u)
GID  := $(shell id -g)

$(if $(shell which $(DOCKER) 2>/dev/null),, $(error "$(DOCKER) not found!"))

UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')

vars:
	@echo "Supported targets:  $(TARGETS)"
	@echo "Project directory:  $(PROJECT_DIR)"
	@echo "Download directory: $(DL_DIR)"
	@echo "Build directory:    $(OUTPUT_DIR)"
	@echo "ccache directory:   $(CCACHE_DIR)"
	@echo "Extra options:      $(EXTRA_OPTS)"
	@echo "Docker options:     $(DOCKER_OPTS)"
	@echo "Make options:       $(MAKE_OPTS)"


build-docker-image:
	$(DOCKER) build . -t $(DOCKER_REPO)/$(IMAGE_NAME)
	@touch .ba-docker-image-available

.ba-docker-image-available:
	@$(DOCKER) pull $(DOCKER_REPO)/$(IMAGE_NAME)
	@touch .ba-docker-image-available

reglinux-docker-image: merge .ba-docker-image-available

update-docker-image:
	-@rm .ba-docker-image-available > /dev/null
	@$(MAKE) reglinux-docker-image

publish-docker-image:
	@$(DOCKER) push $(DOCKER_REPO)/$(IMAGE_NAME):latest

output-dir-%: %-supported
	@mkdir -p $(OUTPUT_DIR)/$*

ccache-dir:
	@mkdir -p $(CCACHE_DIR)

dl-dir:
	@mkdir -p $(DL_DIR)

%-supported:
	$(if $(findstring $*, $(TARGETS)),,$(error "$* not supported!"))

%-clean: reglinux-docker-image output-dir-%
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build -C /build/buildroot clean

%-config: reglinux-docker-image output-dir-%
	@$(PROJECT_DIR)/configs/createDefconfig.sh $(PROJECT_DIR)/configs/rescue-$*
	@for opt in $(EXTRA_OPTS); do \
		echo $$opt >> $(PROJECT_DIR)/configs/rescue-$*_defconfig ; \
	done
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build -C /build/buildroot rescue-$*_defconfig

%-build: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot $(CMD)

%-source: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot source

%-show-build-order: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot show-build-order

%-kernel: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot linux-menuconfig

%-graph-depends: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -it --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make O=/$* BR2_EXTERNAL=/build BR2_GRAPH_OUT=svg -C /build/buildroot graph-depends

%-shell: reglinux-docker-image output-dir-%
	$(if $(BATCH_MODE),$(if $(CMD),,$(error "not suppoorted in BATCH_MODE if CMD not specified!")),)
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-w /$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		$(DOCKER_OPTS) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		$(CMD)

%-ccache-stats: reglinux-docker-image %-config ccache-dir dl-dir
	@$(DOCKER) run -t --init --rm \
		-v $(PROJECT_DIR):/build \
		-v $(DL_DIR):/build/buildroot/dl \
		-v $(OUTPUT_DIR)/$*:/$* \
		-v $(CCACHE_DIR):$(HOME)/.buildroot-ccache \
		-u $(UID):$(GID) \
		-v /etc/passwd:/etc/passwd:ro \
		-v /etc/group:/etc/group:ro \
		$(DOCKER_OPTS) \
		$(DOCKER_REPO)/$(IMAGE_NAME) \
		make $(MAKE_OPTS) O=/$* BR2_EXTERNAL=/build -C /build/buildroot ccache-stats

%-cleanbuild: %-clean %-build
	@echo

%-pkg:
	$(if $(PKG),,$(error "PKG not specified!"))
	@$(MAKE) $*-build CMD=$(PKG)

%-tail: output-dir-%
	@tail -F $(OUTPUT_DIR)/$*/build/build-time.log

%-find-build-dups: %-supported
	@find $(OUTPUT_DIR)/$*/build -maxdepth 1 -type d -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2

%-remove-build-dups: %-supported
	@while [ -n "`find $(OUTPUT_DIR)/$*/build -maxdepth 1 -type d -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2 | grep .`" ]; do \
		find $(OUTPUT_DIR)/$*/build -maxdepth 1 -type d -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2 | xargs rm -rf ; \
	done

find-dl-dups:
	@find $(DL_DIR) -maxdepth 2 -type f -name "*.zip" -o -name "*.tar.*" -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+(\.zip|\.tar\.[2a-z]+)$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2

remove-dl-dups:
	@while [ -n "`find $(DL_DIR) -maxdepth 2 -type f -name "*.zip" -o -name "*.tar.*" -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+(\.zip|\.tar\.[2a-z]+)$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2 | grep .`" ] ; do \
		find $(DL_DIR) -maxdepth 2 -type f -name "*.zip" -o -name "*.tar.*" -printf '%T@ %p %f\n' | sed -r 's:\-[0-9a-f\.]+(\.zip|\.tar\.[2a-z]+)$$::' | sort -k3 -k1 | uniq -f 2 -d | cut -d' ' -f2 | xargs rm -rf ; \
	done

merge:
	CUSTOM_DIR=$(PWD)/custom BUILDROOT_DIR=$(PWD)/buildroot $(PWD)/scripts/mergeToBR.sh

generate:
	CUSTOM_DIR=$(PWD)/custom BUILDROOT_DIR=$(PWD)/buildroot $(PWD)/scripts/generateCustom.sh
