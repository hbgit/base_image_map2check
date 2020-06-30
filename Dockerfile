############################################################
# Dockerfile to build map2check build environment container images
# based on herberthb/llvm-docker-dev:v8 image from:
# https://github.com/hbgit/llvm-docker-dev.git
#
# Usage:
#
#  By gitclone https://github.com/hbgit/Map2Check:
#   $ docker build -t herberthb/base-image-map2check:v8 --no-cache -f Dockerfile .
#   $ docker run -it --name=base_build_mapdevel herberthb/base-image-map2check:v8 /bin/bash
############################################################

# Base image with LLVM 8.0 builded
FROM herberthb/llvm-docker-dev:v8

# Image maintainer.
MAINTAINER <herberthb12@gmail.com>

# Update the repository sources list
RUN apt-get update
RUN apt install -y curl \
     git libcap-dev python-pip unzip \
     libtcmalloc-minimal4 libgoogle-perftools-dev \
     libncurses5-dev zlib1g-dev bison flex \
     libboost-all-dev libgmp-dev libmpfr-dev \
     sqlite3 libsqlite3-dev libbz2-dev gperf

# DOWNLOAD
RUN mkdir -p /deps/src/
WORKDIR /deps/src/

## Download KleeUCLibC:
RUN git clone --branch klee_uclibc_v1.2 https://github.com/klee/klee-uclibc.git

# Download MiniSAT:
RUN git clone  --branch releases/2.2.1 https://github.com/stp/minisat.git

# Download STP:
RUN git clone --branch 2.1.2 https://github.com/stp/stp.git

# Download Z3:
RUN git clone --branch z3-4.8.4 https://github.com/Z3Prover/z3.git

# Download MetaSMT
RUN git clone -b v4.rc2 https://github.com/hbgit/metaSMT.git
##RUN git clone -b development https://github.com/agra-uni-bremen/metaSMT.git

# Download Klee:
RUN git clone --branch v2.1 https://github.com/klee/klee.git

# Download Crab:
RUN git clone --branch llvm-8.0 https://github.com/seahorn/crab-llvm.git

# BUILD/INSTALL:
# LLVM environment variables:
ENV LLVM_VERSION 8.0.0

ENV LLVM_DIR usr/lib/llvm-8/cmake
ENV CXX /usr/bin/clang++-8
ENV CC /usr/bin/clang-8

# KleeUCLibC
WORKDIR /deps/src/klee-uclibc
RUN ./configure --make-llvm-lib --with-llvm-config=/usr/bin/llvm-config-8
RUN make -j8

RUN mkdir -p /deps/install/klee_uclib
RUN make PREFIX=/deps/install/klee_uclib install

# MiniSat
WORKDIR /deps/src/minisat

RUN mkdir -p /deps/install/minisat
RUN mkdir BUILD
WORKDIR /deps/src/minisat/BUILD
RUN cmake -DSTATIC_BINARIES=ON -DCMAKE_INSTALL_PREFIX=/deps/install/minisat -G Ninja ..
RUN ninja install

# STP
WORKDIR /deps/src/stp

RUN mkdir -p /deps/install/stp
RUN mkdir BUILD
WORKDIR /deps/src/stp/BUILD
RUN cmake -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_PYTHON_INTERFACE=OFF -DSTP_TIMESTAMPS:BOOL="OFF" \
    -DCMAKE_CXX_FLAGS_RELEASE=-O2 -DCMAKE_C_FLAGS_RELEASE=-O2 \
    -DMINISAT_LIBRARY=/deps/install/minisat/lib/libminisat.a \
    -DMINISAT_INCLUDE_DIR=/deps/install/minisat/include/ \
    -DCMAKE_INSTALL_PREFIX:PATH=/deps/install/stp -G Ninja ..
RUN ninja install

# Z3
WORKDIR /deps/src/z3
RUN mkdir -p /deps/install/z3
RUN CXX=g++ CC=gcc python scripts/mk_make.py --prefix=/deps/install/z3
RUN cd build && make -j8 && make install

# LibFuzzer
RUN cp /usr/lib/llvm-8/lib/libFuzzer.a /deps/install/fuzzer


ENV CXX ""
ENV CC ""
RUN apt install -y g++-5 gcc-5
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 10
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 20
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 10
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 20
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
RUN update-alternatives --set cc /usr/bin/gcc
RUN update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
RUN update-alternatives --set c++ /usr/bin/g++

# MetaSMT
WORKDIR /deps/src/metaSMT
RUN mkdir -p /deps/install/metasmt
RUN git clone https://github.com/agra-uni-bremen/dependencies.git
RUN ./bootstrap.sh --deps deps/ -j 8 \
    --academic -m RELEASE build/ --install /deps/install/metasmt/ \
    --cmake ./ -DmetaSMT_ENABLE_TESTS=off
#RUN cd /deps/src/metaSMT
RUN make
RUN make install
#RUN cd ../../../

# CRAB
RUN mkdir -p /deps/install/crab
RUN mkdir -p /deps/src/crab-llvm/build
WORKDIR /deps/src/crab-llvm/build
#RUN ls
#RUN pwd

RUN cmake -GNinja \
	-DLLVM_DIR=/usr/lib/llvm-8/lib/cmake/llvm/ \
	-DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-5 \
	-DCMAKE_PROGRAM_PATH=/usr/bin \
	-DCMAKE_INSTALL_PREFIX=/deps/install/crab \
	-DCRAB_USE_LDD=ON -DCRAB_USE_APRON=ON ../

RUN cmake --build . --target extra && cmake ..
RUN cmake --build . --target crab && cmake ..
RUN cmake --build . --target ldd && cmake ..
RUN cmake --build . --target apron && cmake ..
RUN cmake --build . --target install

############ LLVM environment variables:
ENV LLVM_VERSION 8.0.0

ENV LLVM_DIR usr/lib/llvm-8/cmake
ENV CXX /usr/bin/clang++-8
ENV CC /usr/bin/clang-8

# Klee
WORKDIR /deps/src/klee
RUN mkdir -p /deps/install/klee
RUN mkdir build

WORKDIR /deps/src/klee/build
RUN cmake -DENABLE_SOLVER_METASMT=ON \
    -DmetaSMT_DIR=/deps/install/metasmt/share/metaSMT/ \
    -DENABLE_SOLVER_Z3=ON -DZ3_LIBRARIES=/deps/install/z3/lib/libz3.so \
    -DZ3_INCLUDE_DIRS=/deps/install/z3/include -DENABLE_SOLVER_STP=ON \
    -DKLEE_RUNTIME_BUILD_TYPE=Release -DENABLE_POSIX_RUNTIME=ON \
    -DENABLE_KLEE_UCLIBC=ON -DKLEE_UCLIBC_PATH=/deps/install/klee_uclib/usr/x86_64-linux-uclibc/usr/ \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_CONFIG_BINARY=/usr/bin/llvm-config-8 \
    -DENABLE_TCMALLOC=OFF -DENABLE_SYSTEM_TESTS=OFF -DENABLE_UNIT_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH=/deps/install/klee -G Ninja ..

RUN ninja install


# Cleaning Source Files
#RUN rm -rf /deps/src
