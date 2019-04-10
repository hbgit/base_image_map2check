############################################################
# Dockerfile to build map2check build environment container images
# based on herberthb/dev-llvm_6.0:first image from:
# https://github.com/hbgit/dev-llvm_6.0
#
# Usage:
#
#  By gitclone https://github.com/hbgit/Map2Check:
#   $ docker build -t herberthb/base-image-map2check:latest --no-cache -f Dockerfile .
#   $ docker run -it --name=base_build_mapdevel herberthb/base-image-map2check:latest /bin/bash
############################################################

# Base image with LLVM 6.0 builded
FROM hrocha/dev-llvm_6.0:first

# Image maintainer.
MAINTAINER <herberthb12@gmail.com>

# Update the repository sources list
RUN apt-get update
RUN apt install -y git libncurses5-dev zlib1g-dev bison flex  libboost-all-dev libgmp-dev libmpfr-dev

# DOWNLOAD
RUN mkdir -p /deps/src/
WORKDIR /deps/src/

# Download KleeUCLibC:
RUN git clone --branch klee_0_9_29 https://github.com/hbgit/klee-uclibc.git

# Download MiniSAT:
RUN git clone  --branch releases/2.2.1 https://github.com/stp/minisat.git

# Download STP:
RUN git clone --branch 2.1.2 https://github.com/stp/stp.git

# Download Z3:
RUN git clone --branch z3-4.4.1 https://github.com/Z3Prover/z3.git

# Download LibFuzzer:
RUN svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk/lib/fuzzer

# Download Klee:
RUN git clone https://github.com/klee/klee.git

# Download Crab:
RUN git clone --branch dev-llvm-6.0 https://github.com/hbgit/crab-llvm.git

# BUILD/INSTALL:
# LLVM environment variables:
ENV LLVM_DIR_BASE /llvm/release/llvm600
ENV LLVM_VERSION 6.0.0

ENV LLVM_DIR $LLVM_DIR_BASE/lib/cmake/llvm
ENV CXX $LLVM_DIR_BASE/bin/clang++
ENV CC $LLVM_DIR_BASE/bin/clang

# KleeUCLibC
WORKDIR /deps/src/klee-uclibc
RUN ./configure --make-llvm-lib --with-llvm-config=$LLVM_DIR_BASE/bin/llvm-config
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
RUN cmake -DBUILD_SHARED_LIBS=OFF -DENABLE_PYTHON_INTERFACE=OFF -DSTP_TIMESTAMPS:BOOL="OFF" -DCMAKE_CXX_FLAGS_RELEASE=-O2 -DCMAKE_C_FLAGS_RELEASE=-O2 -DMINISAT_LIBRARY=/deps/install/minisat/lib/libminisat.a -DMINISAT_INCLUDE_DIR=/deps/install/minisat/include/ -DCMAKE_INSTALL_PREFIX:PATH=/deps/install/stp -G Ninja ..
RUN ninja install

# Z3
WORKDIR /deps/src/z3
RUN mkdir -p /deps/install/z3
RUN CXX=g++ CC=gcc python scripts/mk_make.py --prefix=/deps/install/z3
RUN cd build && make -j8 && make install

# LibFuzzer
WORKDIR /deps/src/fuzzer
RUN mkdir -p /deps/install/fuzzer
RUN ./build.sh
RUN cp libFuzzer.a /deps/install/fuzzer

# Klee
WORKDIR /deps/src/klee
RUN mkdir -p /deps/install/klee
RUN mkdir build

WORKDIR /deps/src/klee/build
RUN cmake -DENABLE_SOLVER_Z3=ON -DZ3_LIBRARIES=/deps/install/z3/lib/libz3.so -DZ3_INCLUDE_DIRS=/deps/install/z3/include -DENABLE_SOLVER_STP=ON -DKLEE_RUNTIME_BUILD_TYPE=Release -DENABLE_POSIX_RUNTIME=ON -DENABLE_KLEE_UCLIBC=ON -DKLEE_UCLIBC_PATH=/deps/install/klee_uclib/usr/x86_64-linux-uclibc/usr/ -DCMAKE_BUILD_TYPE=Release -DLLVM_CONFIG_BINARY=$LLVM_DIR_BASE/bin/llvm-config \
     -DENABLE_TCMALLOC=OFF -DENABLE_SYSTEM_TESTS=OFF -DENABLE_UNIT_TESTS=OFF -DCMAKE_INSTALL_PREFIX:PATH=/deps/install/klee -G Ninja ..
RUN ninja install

# CRAB
RUN mkdir -p /deps/install/crab
RUN mkdir -p /deps/src/crab-llvm/build
WORKDIR /deps/src/crab-llvm/build
ENV CXX ""
ENV CC ""

RUN cmake -DLLVM_DIR=/llvm/release/llvm600/lib/cmake/llvm/ -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-5 -DCMAKE_PROGRAM_PATH=/usr/bin -DCMAKE_INSTALL_PREFIX=/deps/install/crab -DUSE_LDD=ON -DUSE_APRON=ON ../
RUN cmake --build . --target extra && cmake ..
RUN cmake --build . --target crab && cmake ..
RUN cmake --build . --target ldd && cmake ..
RUN cmake --build . --target apron && cmake ..
RUN cmake --build . --target install

# Cleaning Source Files
RUN rm -rf /deps/src
