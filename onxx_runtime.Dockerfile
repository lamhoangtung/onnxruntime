# --------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
# --------------------------------------------------------------
# Dockerfile to run ONNXRuntime with CUDA, CUDNN integration

# nVidia cuda 10.2 Base Image
FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04
MAINTAINER Changming Sun "chasun@microsoft.com"
ADD . /code

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3.7 python3.7-dev python3-dev ca-certificates g++ gcc make git python3-setuptools python3-wheel python3-pip aria2 && \
    aria2c -q -d /tmp -o cmake-3.19.2-Linux-x86_64.tar.gz https://github.com/Kitware/CMake/releases/download/v3.19.2/cmake-3.19.2-Linux-x86_64.tar.gz && \
    tar -zxf /tmp/cmake-3.19.2-Linux-x86_64.tar.gz --strip=1 -C /usr

RUN cd /code && /bin/bash ./build.sh --skip_submodule_sync --cuda_home /usr/local/cuda --cudnn_home /usr/lib/x86_64-linux-gnu/ --use_cuda --config Release --build_wheel --update --build --parallel --cmake_extra_defines ONNXRUNTIME_VERSION=$(cat ./VERSION_NUMBER) 'CMAKE_CUDA_ARCHITECTURES=52;60;61;70;72;75;80'

FROM nvidia/cuda:11.0-cudnn8-runtime-ubuntu18.04
COPY --from=0 /code/build/Linux/Release/dist /root
COPY --from=0 /code/dockerfiles/LICENSE-IMAGE.txt /code/LICENSE-IMAGE.txt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 ca-certificates python3-setuptools python3-wheel python3-pip python3.7 python3.7-dev unattended-upgrades && unattended-upgrade && python3.7 -m pip install /root/*.whl && rm -rf /root/*.whl
