#!/bin/sh

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DYARPIDL_thrift_LOCATION=$BUILD_PREFIX/bin/yarpidl_thrift -DYARPIDL_rosmsg_LOCATION=$BUILD_PREFIX/bin/yarpidl_rosmsg"
fi

# Workaround for https://github.com/conda-forge/qt-main-feedstock/issues/273
if [[ "$build_platform" != "$target_platform" ]]; then
    export QT_HOST_PATH="$BUILD_PREFIX"
fi

rm -rf build
mkdir -p build

cd build

cmake ${CMAKE_ARGS} -GNinja .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING:BOOL=ON \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DFRAMEWORK_USE_YARP:BOOL=ON \
    -DFRAMEWORK_USE_OsqpEigen:BOOL=ON \
    -DFRAMEWORK_USE_matioCpp:BOOL=ON \
    -DFRAMEWORK_USE_manif:BOOL=ON \
    -DFRAMEWORK_USE_Qhull:BOOL=ON \
    -DFRAMEWORK_USE_cppad:BOOL=ON \
    -DFRAMEWORK_USE_casadi:BOOL=ON \
    -DFRAMEWORK_USE_LieGroupControllers:BOOL=ON \
    -DFRAMEWORK_USE_UnicyclePlanner:BOOL=ON \
    -DFRAMEWORK_USE_tomlplusplus:BOOL=ON \
    -DFRAMEWORK_USE_PCL:BOOL=ON \
    -DFRAMEWORK_COMPILE_PYTHON_BINDINGS:BOOL=OFF \
    -DUSE_SYSTEM_Catch2:BOOL=ON

cat CMakeCache.txt

cmake --build . --config Release
cmake --build . --config Release --target install

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  # QPInverseKinematicsUnitTests excluded as a workaround for https://github.com/conda-forge/bipedal-locomotion-framework-feedstock/issues/29
  ctest --output-on-failure -E QPInverseKinematicsUnitTests  -C Release
fi
