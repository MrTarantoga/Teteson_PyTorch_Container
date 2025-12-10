FROM knallwinkel/pytorch-builder:base AS builder

# Set environment variables for PyTorch build
ENV TORCH_CUDA_ARCH_LIST="8.7"
ENV TORCH_USE_CUDA_DSA=1
ENV CUDA_HOME=/usr/local/cuda
ENV CMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc
ENV USE_CUDA=1
ENV USE_CUDNN=1
ENV USE_CUDSS=1
ENV USE_CUSPARSELT=1
ENV USE_CUFILE=1
ENV USE_NUMPY=1
ENV BUILD_TEST=1
ENV USE_SYSTEM_NCCL=1
ENV BLAS=OpenBLAS
ENV LAPACK=OpenBLAS
ENV USE_OPENBLAS=ON
ENV CMAKE_PREFIX_PATH="/usr:/usr/local/cuda"
ENV CMAKE_INCLUDE_PATH="/usr/include:/usr/include/libcudss/12:/usr/include/libcusparseLt/12"
ENV CMAKE_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu/libcudss/12:/usr/lib/aarch64-linux-gnu/libcusparseLt/12"
ENV MAX_JOBS=1
ENV CXX11_ABI=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    python3-dev \
    python3-pip \
    python3-setuptools \
    libopenblas-dev \
    liblapack-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libgflags-dev \
    libgoogle-glog-dev \
    libsnappy-dev \
    libbz2-dev \
    liblzma-dev \
    libgdbm-dev \
    libncurses5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libffi-dev \
    libgraphviz-dev \
    libzstd-dev \
    libncursesw5-dev \
    libtinfo5 \
    libuuid1 \
    libopenjp2-7-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libnetcdff-dev \
    gfortran \
    libmpich-dev \
    libcudss0-dev-cuda-12 \
    libcusparselt0-dev-cuda-12 \
    libopenblas-dev \
    liblapack-dev \
    libcuda1-535 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --upgrade pip && \
    pip3 install Cython==3.1.6 meson-python patchelf pythran ninja pybind11 \
    build pyyaml typing-extensions wheel astunparse "setuptools<80.0.0" requests cmake

# Create build script instead of using shell functions
RUN echo '#!/bin/bash
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

echo "Build completed successfully"
' > /tmp/build_script.sh && \
    chmod +x /tmp/build_script.sh && \
    /tmp/build_script.sh && \
    rm /tmp/build_script.sh

# Copy wheels to output directory
RUN mkdir -p /output && \
    cp /torch-2.9*.whl /output/ && \
    cp /numpy-*.whl /output/ && \
    cp /scipy-1.16*.whl /output/

# Clean up
RUN rm -rf /root/.cache/pip

# Show what was produced
RUN ls -la /output/

# Set entrypoint to show output
ENTRYPOINT ["sh", "-c", "echo 'Wheels generated in /output:' && ls -la /output/"]