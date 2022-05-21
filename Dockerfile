FROM ubuntu:22.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gpg-agent \
    libbz2-dev \
    software-properties-common \
    ninja-build \
    g++ \
    gcc \
    gfortran \
    libblas3 \
    liblapack3 \
    pkg-config \
    unzip \
    wget \
    coinor-libipopt-dev \
 && rm -rf /var/lib/apt/lists/*

# CMake
RUN mkdir -p /opt && mkdir -p /opt/build && cd /opt/build \
 && curl -L https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-x86_64.sh --output cmake.sh \
 && mkdir -p /opt/dist/usr/local \
 && /bin/bash cmake.sh --prefix=/opt/dist/usr/local --skip-license

# BOOST 1.60 with Boost geometry extensions
# SSC : system thread random chrono
# XDYN : program_options filesystem system regex
# libbz2 is required for Boost compilation
RUN wget --quiet http://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.tar.gz -O boost_src.tar.gz \
 && mkdir -p boost_src \
 && tar -xzf boost_src.tar.gz --strip 1 -C boost_src \
 && rm -rf boost_src.tar.gz \
 && cd boost_src \
 && ./bootstrap.sh \
 && ./b2 cxxflags=-fPIC --without-mpi --without-python link=static threading=single threading=multi --layout=tagged --prefix=/opt/boost install > /dev/null \
 && cd .. \
 && rm -rf boost_src
# BOOST Geometry extension
RUN git clone https://github.com/boostorg/geometry \
 && cd geometry \
 && git checkout 4aa61e59a72b44fb3c7761066d478479d2dd63a0 \
 && cp -rf include/boost/geometry/extensions /opt/boost/include/boost/geometry/. \
 && cd .. \
 && rm -rf geometry
#
## Ipopt
## http://www.coin-or.org/Ipopt/documentation/node10.html
#ENV IPOPT_VERSION=3.12.9
#RUN gfortran --version \
# && wget http://www.coin-or.org/download/source/Ipopt/Ipopt-$IPOPT_VERSION.tgz -O ipopt_src.tgz \
# && mkdir -p ipopt_src \
# && tar -xf ipopt_src.tgz --strip 1 -C ipopt_src \
# && rm -rf ipopt_src.tgz \
# && cd ipopt_src \
# && cd ThirdParty/Blas \
# &&     ./get.Blas \
# && cd ../Lapack \
# &&     ./get.Lapack \
# && cd ../Mumps \
# &&     ./get.Mumps \
# && cd ../../ \
# && mkdir build \
# && cd build \
# && ../configure -with-pic --disable-shared --prefix=/opt/CoinIpopt \
# && make \
# && make test \
# && make install \
# && cd .. \
# && cd .. \
# && rm -rf ipopt_src

RUN wget https://github.com/eigenteam/eigen-git-mirror/archive/3.3.5.tar.gz -O eigen.tgz \
 && mkdir -p /opt/eigen \
 && tar -xzf eigen.tgz --strip 1 -C /opt/eigen \
 && rm -rf eigen.tgz

RUN wget https://github.com/jbeder/yaml-cpp/archive/release-0.3.0.tar.gz -O yaml_cpp.tgz \
 && mkdir -p /opt/yaml_cpp \
 && tar -xzf yaml_cpp.tgz --strip 1 -C /opt/yaml_cpp \
 && rm -rf yaml_cpp.tgz

RUN wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz -O googletest.tgz \
 && mkdir -p /opt/googletest \
 && tar -xzf googletest.tgz --strip 1 -C /opt/googletest \
 && rm -rf googletest.tgz

RUN wget https://github.com/zaphoyd/websocketpp/archive/0.7.0.tar.gz -O websocketpp.tgz \
 && mkdir -p /opt/websocketpp \
 && tar -xzf websocketpp.tgz --strip 1 -C /opt/websocketpp \
 && rm -rf websocketpp.tgz

RUN mkdir -p /opt/libf2c \
 && cd /opt/libf2c \
 && wget http://www.netlib.org/f2c/libf2c.zip -O libf2c.zip \
 && unzip libf2c.zip \
 && rm -rf libf2c.zip

RUN wget https://sourceforge.net/projects/geographiclib/files/distrib/archive/GeographicLib-1.30.tar.gz/download -O geographiclib.tgz \
 && mkdir -p /opt/geographiclib \
 && tar -xzf geographiclib.tgz --strip 1 -C /opt/geographiclib \
 && rm -rf geographiclib.tgz

ENV HDF5_INSTALL=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/src/hdf5-1.8.12.tar.gz -O hdf5_source.tar.gz \
 && mkdir -p HDF5_SRC \
 && tar -xf hdf5_source.tar.gz --strip 1 -C HDF5_SRC \
 && mkdir -p HDF5_build \
 && cd HDF5_build \
 && /opt/dist/usr/local/bin/cmake \
      -G "Unix Makefiles" \
      -D CMAKE_C_COMPILER=icc \
      -D CMAKE_CXX_COMPILER=icpc \
      -D CMAKE_FC_COMPILER=ifort \
      -D CMAKE_BUILD_TYPE:STRING=Release \
      -D CMAKE_INSTALL_PREFIX:PATH=${HDF5_INSTALL} \
      -D BUILD_SHARED_LIBS:BOOL=OFF \
      -D BUILD_TESTING:BOOL=OFF \
      -D HDF5_BUILD_TOOLS:BOOL=OFF \
      -D HDF5_BUILD_EXAMPLES:BOOL=OFF \
      -D HDF5_BUILD_HL_LIB:BOOL=ON \
      -D HDF5_BUILD_CPP_LIB:BOOL=ON \
      -D HDF5_BUILD_FORTRAN:BOOL=OFF \
      -D CMAKE_C_FLAGS="-fPIC" \
      -D CMAKE_CXX_FLAGS="-fPIC" \
      ../HDF5_SRC \
 && make install \
 && cd .. \
 && rm -rf hdf5_source.tar.gz HDF5_SRC HDF5_build

RUN cd /opt \
 && git clone https://github.com/garrison/eigen3-hdf5 \
 && cd eigen3-hdf5 \
 && git checkout 2c782414251e75a2de9b0441c349f5f18fe929a2

ARG GIT_GRPC_TAG=v1.30.2
RUN git clone --recurse-submodules -b ${GIT_GRPC_TAG} https://github.com/grpc/grpc grpc_src \
 && cd grpc_src \
 && mkdir -p cmake/build \
 && cd cmake/build \
 && /opt/dist/usr/local/bin/cmake \
      -G "Unix Makefiles" \
      -D gRPC_INSTALL:BOOL=ON \
      -D CMAKE_INSTALL_PREFIX=/opt/grpc \
      -D CMAKE_BUILD_TYPE=Release \
      -D gRPC_BUILD_TESTS:BOOL=OFF \
      -D BUILD_SHARED_LIBS:BOOL=OFF \
      -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
      -D CMAKE_C_FLAGS="-fPIC" \
      -D CMAKE_CXX_FLAGS="-fPIC" \
      -D CMAKE_VERBOSE_MAKEFILE:BOOL=OFF \
      ../.. \
 && make install \
 && cd ../../.. \
 && rm -rf grpc_src

ENV CMAKE_PREFIX_PATH='/opt/intel/oneapi/tbb/latest:/opt/intel/oneapi/compiler/latest/linux/IntelDPCPP'
ENV ONEAPI_ROOT='/opt/intel/oneapi'
ENV PATH='/opt/intel/oneapi/mpi/latest/libfabric/bin:/opt/intel/oneapi/mpi/latest/bin:/opt/intel/oneapi/dev-utilities/latest/bin:/opt/intel/oneapi/debugger/latest/gdb/intel64/bin:/opt/intel/oneapi/compiler/latest/linux/lib/oclfpga/bin:/opt/intel/oneapi/compiler/latest/linux/bin/intel64:/opt/intel/oneapi/compiler/latest/linux/bin:/opt/dist/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
