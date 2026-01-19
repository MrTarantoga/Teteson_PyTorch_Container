#!/bin/bash
set -e

# Build PyTorch
echo "Building PyTorch..."
git clone --branch v2.9.1 --single-branch --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git submodule sync
git submodule update --init --recursive
python3 -m build --no-isolation --wheel
pip3 install dist/*.whl
mv dist/torch-2.9*.whl /
cd ..
rm -rf pytorch
