all: update-submodules ubuntu-intel

DOCKER_AS_ROOT:=docker run -t --rm -w /opt/share -v $(shell pwd)/xdyn:/opt/share
DOCKER_AS_USER:=$(DOCKER_AS_ROOT) -u $(shell id -u):$(shell id -g)

MAKE:=make \
BUILD_TYPE=Release \
BUILD_DIR=build_ubuntu2204 \
CPACK_GENERATOR=DEB \
DOCKER_IMAGE=gjacquenot/xdynubuntu \
BOOST_ROOT=/opt/boost \
HDF5_DIR=/usr/local/hdf5/share/cmake \
BUILD_PYTHON_WRAPPER=False

ubuntu-intel: headers ubuntu_22_04_release_gcc_10

headers:
	${MAKE} -C xdyn headers

update-submodules:
	@echo "Updating Git submodules..."
	@git submodule sync --recursive
	@git submodule update --init --recursive
	@git submodule foreach --recursive 'git fetch --tags'

ubuntu_22_04_release_gcc_10: BUILD_TYPE = Release
ubuntu_22_04_release_gcc_10: BUILD_DIR = build_deb11
ubuntu_22_04_release_gcc_10: CPACK_GENERATOR = DEB
ubuntu_22_04_release_gcc_10: DOCKER_IMAGE = gjacquenot/xdynubuntu
ubuntu_22_04_release_gcc_10: BOOST_ROOT = /opt/boost
ubuntu_22_04_release_gcc_10: HDF5_DIR = /usr/local/hdf5/share/cmake
ubuntu_22_04_release_gcc_10: BUILD_PYTHON_WRAPPER = False
ubuntu_22_04_release_gcc_10: cmake-ubuntu-intel-target build-ubuntu-intel test-ubuntu-intel

xdyn/code/yaml-cpp/CMakeLists.txt:
	${MAKE} -C xdyn code/yaml-cpp/CMakeLists.txt

cmake-ubuntu-intel-target: SHELL:=/bin/bash
cmake-ubuntu-intel-target: xdyn/code/yaml-cpp/CMakeLists.txt
	docker pull $(DOCKER_IMAGE) || true
	$(DOCKER_AS_USER) $(DOCKER_IMAGE) /bin/bash -c \
	   "cd /opt/share &&\
	    mkdir -p $(BUILD_DIR) &&\
	    cd $(BUILD_DIR) &&\
	    cmake -Wno-dev \
	     -G Ninja \
	     -D THIRD_PARTY_DIRECTORY=/opt/ \
	     -D BUILD_DOCUMENTATION:BOOL=False \
	     -D CPACK_GENERATOR=$(CPACK_GENERATOR) \
	     -D CMAKE_BUILD_TYPE=$(BUILD_TYPE) \
	     -D CMAKE_INSTALL_PREFIX:PATH=/opt/xdyn \
	     -D HDF5_DIR=$(HDF5_DIR) \
	     -D BOOST_ROOT:PATH=$(BOOST_ROOT) \
	     -D BUILD_PYTHON_WRAPPER:BOOL=$(BUILD_PYTHON_WRAPPER) \
	     $(ADDITIONAL_CMAKE_PARAMETERS) \
	    /opt/share/code"

build-ubuntu-intel: SHELL:=/bin/bash
build-ubuntu-intel:
	$(DOCKER_AS_USER) $(DOCKER_IMAGE) /bin/bash -c \
	   "cd /opt/share && \
	    mkdir -p $(BUILD_DIR) && \
	    cd $(BUILD_DIR) && \
	    ninja $(NB_OF_PARALLEL_BUILDS) package"

test-ubuntu-intel: SHELL:=/bin/bash
test-ubuntu-intel:
	$(DOCKER_AS_USER) $(DOCKER_IMAGE) /bin/bash -c \
	   "cp validation/codecov_bash.sh $(BUILD_DIR) && \
	    cd $(BUILD_DIR) &&\
	    ./run_all_tests &&\
	    if [[ $(BUILD_TYPE) == Coverage ]];\
	    then\
	    echo Coverage;\
	    gprof run_all_tests gmon.out > gprof_res.txt 2> gprof_res.err;\
	    bash codecov_bash.sh && \
	    rm codecov_bash.sh;\
	    fi"

xdyn.deb: build_deb11/xdyn.deb
	@cp $< $@

build_deb11/xdyn.deb:
	@echo "Run ./ninja_debian.sh package"

clean:
	rm -f xdyn.deb
	rm -rf build_*
	rm -rf yaml-cpp
	@${MAKE} -C doc_user clean; rm -f doc_user/xdyn.deb doc.html
	@${MAKE} -C code/wrapper_python clean
