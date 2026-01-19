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
build-essential \
lcov pkg-config clang cmake ninja-build \
libbz2-dev libffi-dev libgdbm-dev \
libgdbm-compat-dev liblzma-dev \
libncurses5-dev libreadline-dev libsqlite3-dev \
libssl-dev libgraphviz-dev lzma-dev tk-dev uuid-dev libzstd-dev \
zlib1g-dev git libopenjp2-7-dev libfreetype6-dev \
liblcms2-dev libwebp-dev libnetcdff-dev gfortran \
libmpich-dev libcusparselt0-dev-cuda-12 libcudss0-dev-cuda-12 \
libbz2-1.0 libffi8 libgdbm6 libgdbm-compat4 liblzma5 libzstd1 \
libtinfo6 libreadline8 libsqlite3-0 graphviz \
zlib1g tk libuuid1  git libopenjp2-7-dev libopenjp2-7 liblcms2-2 libwebpmux3 libwebpdemux2 libwebp7 \
libnetcdff7 gfortran libgomp1 libcusparselt0-cuda-12 libcudss0-cuda-12

# Install Python packages
RUN pip3 install --upgrade pip && \
    pip3 install Cython==3.1.6 meson-python patchelf pythran ninja pybind11 \
    build pyyaml typing-extensions wheel astunparse "setuptools<80.0.0" requests cmake

COPY builder_numpy.sh /builder_numpy.sh
COPY builder_scipy.sh /builder_scipy.sh
COPY builder_torch.sh /builder_torch.sh

RUN bash /builder_numpy.sh
RUN bash /builder_scipy.sh
RUN bash /builder_torch.sh

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
