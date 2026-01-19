#!/bin/bash
set -e

# Install xtl
echo "Installing xtl..."
git clone --branch 0.8.1 --single-branch --recursive https://github.com/xtensor-stack/xtl.git
cd xtl
cmake -DCMAKE_INSTALL_PREFIX=/usr .
make -j$(nproc)
make install
cd ..
rm -rf xtl

# Install xsimd
echo "Installing xsimd..."
git clone --branch 13.2.0 --single-branch --recursive https://github.com/xtensor-stack/xsimd.git
cd xsimd
cmake -DCMAKE_INSTALL_PREFIX=/usr .
make -j$(nproc)
make install

cd ..
rm -rf xsimd

# Build numpy
echo "Building numpy..."
export NPY_BLAS_ORDER=openblas
export NPY_USE_BLAS_ILP64=1
git clone --branch v2.3.5 --single-branch --recursive https://github.com/numpy/numpy.git
cd numpy
git submodule update --init
python3 -m build --no-isolation --wheel
pip3 install dist/*.whl
mv dist/numpy-*.whl /
cd ..
rm -rf numpy
