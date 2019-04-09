# Docker File

This Dockerfile builds map2check build environment container images
based on herberthb/dev-llvm_6.0:first image from: https://github.com/hbgit/dev-llvm_6.0

# Usage:
From gitclone:

``` bash
$ docker build -t herberthb/base-image-map2check:latest --no-cache -f Dockerfile .
```

Dockerfile adopts the sources from:
- klee_0_9_29 https://github.com/klee/klee-uclibc.git
- releases/2.2.1 https://github.com/stp/minisat.git
- 2.1.2 https://github.com/stp/stp.git
- z3-4.4.1 https://github.com/Z3Prover/z3.git
- http://llvm.org/svn/llvm-project/compiler-rt/trunk/lib/fuzzer
- map2check_svcomp2018 https://github.com/RafaelSa94/klee.git
- dev-llvm-6.0 https://github.com/hbgit/crab-llvm.git
