# Use an official image as a base
FROM ubuntu:22.04

# Update and install necessary packages
RUN apt update && apt install -y \
    sudo \
    lib32ncurses5-dev \
    swig \
    python3-dev \
    python2-dev \
    lib32z1 \
    libssl-dev \
    flex \
    bison \
    device-tree-compiler \
    bc \
    file \
    wget \
    build-essential \
    libgmp-dev \
    libmpc-dev \
    cpio \
    g++ \
    patch \
    unzip \
    rsync \
    fakeroot \
    git \
    debootstrap \
    qemu-user-static \
    multistrap \
    qemu \
    binfmt-support \
    dpkg-cross && \
    ln -s /usr/bin/python2 /usr/bin/python

# Create a non-root user and group
RUN groupadd -g 1000 user && \
    useradd -u 1000 -g 1000 -m -s /usr/sbin/nologin user && \
    echo "user:licheepi" | chpasswd && \
    echo "root:licheepi" | chpasswd && \
    adduser user sudo

# Create necessary directories with proper permissionsd
RUN mkdir -p /home/user/toolchains/ && chown -R user:user /home/user/

# Download toolchains
ADD https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/arm-linux-gnueabi/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabi.tar.xz /home/user/toolchains/arm-linux-gnueabi.tar.xz
ADD https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/arm-linux-gnueabihf/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf.tar.xz /home/user/toolchains/arm-linux-gnueabihf.tar.xz

# Extract and move toolchains, then clean up
RUN tar -xf /home/user/toolchains/arm-linux-gnueabi.tar.xz --directory=/home/user/toolchains/ && \
    mv /home/user/toolchains/*arm-linux-gnueabi/ /home/user/toolchains/arm-linux-gnueabi/ && \
    ln -s /home/user/toolchains/arm-linux-gnueabi/bin/arm-linux-gnueabi* /usr/bin/ && \
    tar -xf /home/user/toolchains/arm-linux-gnueabihf.tar.xz --directory=/home/user/toolchains/ && \
    mv /home/user/toolchains/*arm-linux-gnueabihf/ /home/user/toolchains/arm-linux-gnueabihf/ && \
    ln -s /home/user/toolchains/arm-linux-gnueabihf/bin/arm-linux-gnueabihf* /usr/bin/ && \
    rm /home/user/toolchains/*.tar.xz

# Set the working directory
WORKDIR /home/user

# Switch to the non-root user
USER user

# Run the application or start a shell
CMD ["/bin/bash"]
