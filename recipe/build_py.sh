#!/bin/sh

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

CXXFLAGS="${CXXFLAGS} -DPYBIND11_DETAILED_ERROR_MESSAGES"

# Workaround for https://github.com/conda-forge/qt-main-feedstock/issues/273
if [[ "$build_platform" != "$target_platform" ]]; then
    export QT_HOST_PATH="$BUILD_PREFIX"
fi

cd ${SRC_DIR}/bindings

rm -rf build
mkdir build
cd build

cmake ${CMAKE_ARGS} -GNinja .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DPython3_EXECUTABLE:PATH=$PYTHON \
    -DFRAMEWORK_DETECT_ACTIVE_PYTHON_SITEPACKAGES:BOOL=ON

ninja -v
cmake --build . --config Release --target install

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
  # Workaround for https://github.com/conda-forge/mumps-feedstock/issues/125
  export OMP_NUM_THREADS=1
  # Tests are not installed, so we run them during the build
  # We run them directly via pytest so we detect if we are not compiling some required components
  cd ..
  pytest -v -k "not (test_load_from_file or test_fixed_foot_detector)"
fi
