#!/bin/bash
set -euo pipefail

printf "⭐️ Setting up spack environment for Dyninst\n"
. /opt/spack/share/spack/setup-env.sh
spack env activate .
mkdir -p build/dyninst

# 1. Build Dyninst
printf "⭐️ Preparing to build Dyninst\n"
echo "::group::build dyninst"   
cd build/dyninst
cmake -H/code -B. -DCMAKE_INSTALL_PREFIX=. > >(tee config.out) 2> >(tee config.err >&2)
make VERBOSE=1 -j2 > >(tee build.out) 2> >(tee build.err >&2)
make install VERBOSE=1 -j2 > >(tee build-install.out) 2> >(tee build-install.err >&2)
echo "::endgroup::"

# 2. Build the test suite
printf "⭐️ Preparing to build the testsuite\n"
echo "::group::build tests"   
cd /opt/dyninst-env/
mkdir -p build/testsuite/tests
cd build/testsuite
cmake -H/opt/testsuite -B. -DDyninst_DIR=/opt/dyninst-env/build/dyninst/lib/cmake/Dyninst > >(tee config.out) 2> >(tee config.err >&2)
make VERBOSE=1 -j2 > >(tee build.out) 2> >(tee build.err >&2)
make install VERBOSE=1 -j2 > >(tee build-install.out) 2> >(tee build-install.err >&2)
echo "::endgroup::"

# 3. Run the tests
printf "⭐️ Running tests...\n"
cd /opt/dyninst-env/build/testsuite
export DYNINSTAPI_RT_LIB=/opt/dyninst-env/build/dyninst/lib/libdyninstAPI_RT.so
export OMP_NUM_THREADS=2
export LD_LIBRARY_PATH=/opt/dyninst-env/build/dyninst/lib:$PWD:$LD_LIBRARY_PATH
./runTests -64 -all -log test.log -j1 #> >(tee stdout.log) 2> >(tee stderr.log >&2)

# Run the build script to collect and process the logs then upload them
# cd /opt/dyninst-env                                                                                   && \
# perl /opt/testsuite/scripts/build/build.pl --hostname=ci-github --quiet --restart=build --no-run-tests --upload --auth-token=xxxxxxxxxxxxxxxxxxx
