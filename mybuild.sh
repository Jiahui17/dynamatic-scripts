#!/usr/bin/env bash

#----------------------------------------------------------------------------
#- This script compiles dynamatic; the Polygeist is assumed to be pre-built
#-   and located in /opt/polygeist
#----------------------------------------------------------------------------

# this script should be called from dynamatic's source directory
SCRIPT_CWD="$PWD"

CMAKE="/usr/bin/cmake"
POLYGEIST_DIR_PREFIX="/opt/polygeist"

# export CCACHE_DISABLE=1

LSQ_GEN_PATH="tools/backend/lsq-generator-chisel"
LSQ_GEN_JAR="target/scala-2.13/lsq-generator.jar"

[ -d "/opt/gurobi1103" ] && {
  export GUROBI_HOME="/opt/gurobi1103/linux64"
  export PATH="${PATH}:${GUROBI_HOME}/bin"
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
}

# ----------------------------------------------------------------------------------
# - here are some settings for our centos/rocky servers (identified by the hostname)
# ----------------------------------------------------------------------------------

[ "$(hostname)" = 'ee-tik-dynamo-eda1' ] && {
  source /opt/rh/gcc-toolset-13/enable
}

# ----------------------------------------------------------------------------------
# - Clang configs
# ----------------------------------------------------------------------------------

LLVM_PREFIX="$POLYGEIST_DIR_PREFIX/llvm-project"

C_COMPILER="/usr/bin/clang"
CXX_COMPILER="/usr/bin/clang++"

CMAKE_FLAGS_SUPER="\
  -DCMAKE_C_COMPILER=$C_COMPILER \
  -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
  -DLLVM_ENABLE_LLD=ON \
  "

# Run CMAKE for dynamatic
build_dynamatic () {
  cd $SCRIPT_CWD && mkdir -p build && cd build

  $CMAKE -G Ninja .. \
    -DMLIR_DIR=$LLVM_PREFIX/build/lib/cmake/mlir \
    -DLLVM_DIR=$LLVM_PREFIX/build/lib/cmake/llvm \
    -DCLANG_DIR=$LLVM_PREFIX/build/lib/cmake/clang \
    -DPolly_DIR=$LLVM_PREFIX/build/tools/polly/lib/cmake/polly \
    -DLLVM_TARGETS_TO_BUILD="host" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    $CMAKE_FLAGS_SUPER

  ninja -j 32
}

make_simlink () {
  # Create bin/ directory at the project's root
  cd "$SCRIPT_CWD" && mkdir -p bin bin/generators

  # Create symbolic links to all binaries we use from subfolders
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/cgeist ./bin/cgeist
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/build/bin/polygeist-opt ./bin/polygeist-opt
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/llvm-project/build/bin/clang++ ./bin/clang++

  ln -f --symbolic $SCRIPT_CWD/build/bin/dynamatic ./bin/dynamatic
  ln -f --symbolic $SCRIPT_CWD/build/bin/dynamatic-opt ./bin/dynamatic-opt
  ln -f --symbolic $SCRIPT_CWD/build/bin/exp-frequency-profiler ./bin/exp-frequency-profiler
  ln -f --symbolic $SCRIPT_CWD/build/bin/export-dot ./bin/export-dot
  ln -f --symbolic $SCRIPT_CWD/build/bin/export-rtl ./bin/export-rtl
  ln -f --symbolic $SCRIPT_CWD/build/bin/export-cfg ./bin/export-cfg
  ln -f --symbolic $SCRIPT_CWD/build/bin/handshake-simulator ./bin/handshake-simulator
  ln -f --symbolic $SCRIPT_CWD/build/bin/hls-verifier ./bin/hls-verifier
  ln -f --symbolic $SCRIPT_CWD/build/bin/wlf2csv ./bin/wlf2csv

  ln -f --symbolic $SCRIPT_CWD/build/bin/rtl-constant-generator-verilog ./bin/generators/rtl-constant-generator-verilog
  ln -f --symbolic $SCRIPT_CWD/build/bin/exp-sharing-wrapper-generator ./bin/generators/exp-sharing-wrapper-generator
  ln -f --symbolic $SCRIPT_CWD/build/bin/rtl-cmpf-generator ./bin/generators/rtl-cmpf-generator
  ln -f --symbolic $SCRIPT_CWD/build/bin/rtl-cmpi-generator ./bin/generators/rtl-cmpi-generator
  ln -f --symbolic $SCRIPT_CWD/build/bin/rtl-text-generator ./bin/generators/rtl-text-generator

  ln -f --symbolic "$SCRIPT_CWD/$LSQ_GEN_PATH/$LSQ_GEN_JAR" ./bin/generators/lsq-generator.jar


  # Create symbolic links to polygeist headers
  ln -f --symbolic $POLYGEIST_DIR_PREFIX/llvm-project/clang/lib/Headers $SCRIPT_CWD/build/include/polygeist

  cd "$SCRIPT_CWD" && mkdir -p bin/generators

  # Make the scripts used by the frontend executable
  chmod +x tools/dynamatic/scripts/*.sh
}


build_lsq() {
  cd "$SCRIPT_CWD/$LSQ_GEN_PATH"
  sbt assembly
  chmod +x $LSQ_GEN_JAR
}

build_dynamatic
# build_lsq
make_simlink
