#!/bin/bash
set -e

# Build scipy
echo "Building scipy..."
git clone --branch v1.16.3 --single-branch --recursive https://github.com/scipy/scipy.git
cd scipy
git submodule update --init
python3 -m build -Csetup-args=-Dblas=openblas -Csetup-args=-Dlapack=openblas --no-isolation --wheel --skip-dependency-check
pip3 install dist/*.whl
mv dist/scipy-1.16*.whl /
cd ..
rm -rf scipy
