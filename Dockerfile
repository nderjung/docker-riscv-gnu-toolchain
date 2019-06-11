FROM ubuntu:18.04 AS riscv-build

LABEL maintainer Alexander Jung <a.jung@lancs.ac.uk>

ARG LINUX_KERN=4.20

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKRDIR=/opt/riscv
ENV RISCV=$WORKRDIR/riscv-tools
RUN mkdir -p $RISCV
ENV PATH=$RISCV/bin:$PATH
WORKDIR /opt/riscv

# Add non-free apt sources
#RUN sed -i "s#deb http://deb.debian.org/debian buster main#deb http://deb.debian.org/debian buster main contrib non-free#g" /etc/apt/sources.list

# Install dependencies
RUN apt-get -y update \
 && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      autotools-dev \
      bc \
      bison \
      build-essential \
      ca-certificates \
      curl \
      dejagnu \
      device-tree-compiler \
      expect \
      flex \
      gawk \
      g++-6 \
      gcc-6 \
      git \
      gperf \
      libmpc-dev \
      libmpfr-dev \
      libgmp-dev \
      libtool \
      libexpat-dev \
      libusb-1.0-0-dev \
      ncurses-dev \
      patchutils \
      pkg-config \
      squashfs-tools \
      texinfo \
      openocd \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Get and build requists of riscv-linux
RUN git clone --progress -b riscv-linux-$LINUX_KERN https://github.com/riscv/riscv-linux.git $WORKRDIR/riscv-linux
RUN git clone --progress --recursive https://github.com/riscv/riscv-tools.git $WORKRDIR/riscv-tools
RUN git clone --progress --recursive https://github.com/riscv/riscv-gnu-toolchain $WORKRDIR/riscv-gnu-toolchain

# Build riscv-linux
RUN cd $WORKRDIR/riscv-linux \
 && make \
      ARCH=riscv \
        headers_check \
 && make \
      ARCH=riscv \
      INSTALL_HDR_PATH=$WORKRDIR/riscv-tools/riscv-gnu-toolchain/linux-headers \
        headers_install

# Build riscv-openocd
RUN cd $WORKRDIR/riscv-tools/riscv-openocd \
 && ./bootstrap \
 && mkdir build \
 && cd build \
 && ../configure --prefix=$RISCV --enable-remote-bitbang --enable-jtag_vpi --disable-werror \
 && make \
 && make install

# Build riscv-isa-sim
RUN cd $WORKRDIR/riscv-tools/riscv-isa-sim \
 && mkdir build \
 && cd build \
 && ../configure --prefix=$RISCV --host=riscv64-unknown-elf \
 && make \
 && make install

# Build riscv-gnu-toolchain
RUN cd $WORKRDIR/riscv-gnu-toolchain \
 && ./configure \
      --prefix=$WORKRDIR \
      --enable-multilib \
 && make linux

# Build riscv-pk
RUN cd $WORKRDIR/riscv-tools/riscv-pk \
 && mkdir build \
 && cd build \
 && bash -c ../configure --prefix=$RISCV --host=riscv64-unknown-elf \
 && make \
 && make install

# Run a simple test to make sure at least spike, pk and the Newlib
# compiler are setup correctly.
RUN mkdir -p $WORKRDIR/test
WORKDIR $WORKRDIR/test
RUN echo '#include <stdio.h>\n int main(void) { printf("Hello \
  world!\\n"); return 0; }' > hello.c && \
  riscv64-unknown-elf-gcc -o hello hello.c && spike pk hello

# FROM scratch as riscv-tools
# COPY --from=riscv-build /bin/ /bin
