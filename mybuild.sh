#!/usr/bin/env bash

#----------------------------------------------------------------------------
#- This script fetch the circt from remote, and compile circt and dynamatic
#----------------------------------------------------------------------------

# this script should be called from dynamatic's source directory
SCRIPT_CWD=$PWD

[ "$HOST" == 'ee-tik-eda2' ] &&
  POLYGEIST_DIR_PREFIX='/opt/polygeist-lap' || POLYGEIST_DIR_PREFIX='/opt/polygeist'

LLVM_PREFIX="$POLYGEIST_DIR_PREFIX/llvm-project"

[ -d /opt/gurobi1000 ] && {
  export GUROBI_HOME="/opt/gurobi1000/linux64"
  export PATH="${PATH}:${GUROBI_HOME}/bin"
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
}

CMAKE_FLAGS_SUPER="-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DLLVM_ENABLE_LLD=ON"

which cmake3 && CMAKE=cmake3 || CMAKE=cmake

[ "$HOST" == 'ee-tik-eda2' ] && CMAKE="/opt/"cmake-3.*.*-linux-x86_64"/bin/cmake"

#---------------------
#- Wrapper functions -
#---------------------

build_dynamatic () {
  cd $SCRIPT_CWD && mkdir -p build && cd build
  $CMAKE -G Ninja ..  -DMLIR_DIR=$LLVM_PREFIX/build/lib/cmake/mlir \
    -DLLVM_DIR=$LLVM_PREFIX/build/lib/cmake/llvm \
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    $CMAKE_FLAGS_SUPER
    ninja -j6
  }

  make_simlink () {
    # Create bin/ directory at the project's root
    cd "$SCRIPT_CWD" && mkdir -p bin

  # Create symbolic links to all binaries we use from subfolders
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/cgeist ./bin/cgeist
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/polygeist-opt ./bin/polygeist-opt
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/llvm-project/build/bin/clang++ ./bin/clang++
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/llvm-project/build/bin/mlir-opt ./bin/mlir-opt
  ln -f --symbolic ../build/bin/dynamatic ./bin/dynamatic
  ln -f --symbolic ../build/bin/dynamatic-opt ./bin/dynamatic-opt
  ln -f --symbolic ../build/bin/exp-frequency-profiler ./bin/exp-frequency-profiler
  ln -f --symbolic ../build/bin/export-dot ./bin/export-dot
  ln -f --symbolic ../build/bin/export-vhdl ./bin/export-vhdl
  ln -f --symbolic ../build/bin/handshake-simulator ./bin/handshake-simulator
  ln -f --symbolic ../build/bin/hls-verifier ./bin/hls-verifier
  ln -f --symbolic ../build/bin/exp-export-smv ./bin/exp-export-smv

  # Make the scripts used by the frontend executable
  chmod +x tools/dynamatic/scripts/*.sh

  # Symlink llvm
  [ ! -L $SCRIPT_CWD/polygeist/llvm-project ] && {
    ln --symbolic $POLYGEIST_DIR_PREFIX/llvm-project $SCRIPT_CWD/polygeist/llvm-project
  }
}

build_dynamatic
make_simlink
