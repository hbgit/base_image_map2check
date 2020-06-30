# Docker File

This Dockerfile builds map2check build environment container images
based on herberthb/llvm-docker-dev:v8 image from: https://github.com/hbgit/llvm-docker-dev.git

# Usage:
From gitclone:

``` bash
$ docker build -t herberthb/base-image-map2check:v8 --no-cache -f Dockerfile .
```

Dockerfile adopts the sources from:
|Tool|Version|URL
|---|---|---|
Klee_uclibc     |v1.2|        https://github.com/klee/klee-uclibc.git
Minisat         |v2.2.1|      https://github.com/stp/minisat.git
STP             |v2.1.2|      https://github.com/stp/stp.git
Z3              |v4.8.4|      https://github.com/Z3Prover/z3.git
MetaSMT         |v4.rc2|      https://github.com/hbgit/metaSMT.git
Klee            |v2.1|        https://github.com/klee/klee.git
Crab-LLVM       |llvm-8.0|    https://github.com/seahorn/crab-llvm.git
