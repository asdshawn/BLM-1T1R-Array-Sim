# 使用 Ubuntu 22.04
FROM ubuntu:22.04

# 設定環境變數
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安裝系統工具與函式庫
# ngspice 編譯工具 + wget (下載用) + ghostscript (轉圖用)
RUN apt-get update && apt-get install -y \
    build-essential git curl wget autoconf automake libtool bison flex \
    libreadline-dev libx11-dev libxaw7-dev libxmu-dev libxext-dev libxft-dev \
    libfontconfig1-dev libxrender-dev libfreetype6-dev ca-certificates \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# 2. 下載並編譯 ngspice
WORKDIR /tmp/ngspice_src
RUN git clone --depth 1 https://git.code.sf.net/p/ngspice/ngspice . && \
    ./autogen.sh && \
    ./configure --enable-osdi --enable-xspice --enable-cider --enable-openmp --with-readline=yes --disable-debug && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/ngspice_src

# 3. 安裝 OpenVAF (使用官方 Binary)
WORKDIR /tmp
# 下載 -> 解壓 -> 移動到系統路徑 (/usr/local/bin) -> 清理
RUN wget https://openva.fra1.cdn.digitaloceanspaces.com/openvaf_23_5_0_linux_amd64.tar.gz && \
    tar -xzf openvaf_23_5_0_linux_amd64.tar.gz && \
    cp openvaf /usr/local/bin/ && \
    chmod +x /usr/local/bin/openvaf && \
    rm -rf *

# 4. 設定工作目錄
WORKDIR /work
CMD ["/bin/bash"]