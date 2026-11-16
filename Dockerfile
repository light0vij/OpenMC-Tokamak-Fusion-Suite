
# Dockerfile

FROM ubuntu:24.04


ENV DEBIAN_FRONTEND=noninteractive TZ=UTC PIP_BREAK_SYSTEM_PACKAGES=1
ARG OPENMC_VERSION=v0.16.0
ARG COMPILE_CORES=4


RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git wget python3-dev python3-pip \
        libhdf5-dev libpng-dev gfortran \
    && rm -rf /var/lib/apt/lists/*

# curl is used by the healthcheck in docker-compose.yml
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    xvfb \
    curl \
    && rm -rf /var/lib/apt/lists/*


RUN git clone --depth 1 --branch ${OPENMC_VERSION} https://github.com/openmc-dev/openmc.git /opt/openmc \
    && cmake -S /opt/openmc -B /opt/openmc/build -DOPENMC_USE_OPENMP=on -DCMAKE_BUILD_TYPE=Release \
    && cmake --build /opt/openmc/build -j${COMPILE_CORES} --target install \
    && ldconfig \
    && pip3 install /opt/openmc \
    && rm -rf /opt/openmc/build


COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt \
    && mkdir -p /workspace/notebooks /workspace/chain /nuclear_data

WORKDIR /workspace
COPY notebooks/ notebooks/
# chain/ holds the depletion chain: /workspace/chain/chain_fendl30_fusion_complete.xml
COPY chain/ chain/

EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--no-browser", "--ip=0.0.0.0", "--port=8888", \
     "--ServerApp.token=", "--ServerApp.password=", "--ServerApp.root_dir=/workspace"]
