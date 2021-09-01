#!/bin/bash

Usage() {
  echo "Configure and install deps"
  echo ""
  echo "  Usage: $0 [OPTIONS]"
  echo ""
  echo "    OPTIONS                        DESCRIPTION"
  echo "    --enable-clangd                Enable install clangd"
  echo "    --enable-symbol                Enable install ctags and global"
  echo "    --enable-rg                    Enable install ripgrep"
}


ENABLE_CLANGD=0
ENABLE_SYMBOL=0
ENABLE_RG=0


while [[ $# -gt 0 ]]; do
  case $1 in
    "--help"|"-h")   Usage; exit 1 ;;
    "--enable-clangd")  ENABLE_CLANGD=1 ;;
    "--enable-symbol")  ENABLE_SYMBOL=1 ;;
    "--enable-rg")     ENABLE_RG=1 ;;
    *)
      echo UNKNOWN OPTION $1
      echo Run $0 -h for help
      exit 1
  esac
  shift 1
done

workdir=$(cd $(dirname $0);pwd)

# Install nodejs for coc.nvim
if [ ! -x "$(command -v node)" ];then 
    curl -sL install-node.now.sh | sh
    curl --compressed -o- -L https://yarnpkg.com/install.sh | bash
fi

# Step1
git submodule update --init --recursive

# Step2 install LeaderF
cd start/LeaderF && ./install.sh && cd -

# Step3 install Coc.nvim extension
# json
vim -c ":CocInstall coc-json" -c ":q"
# python
vim -c ":CocInstall coc-pyright" -c ":q"
# bash
vim -c ":CocInstall coc-sh" -c ":q"

if [[ $ENABLE_CLANGD -eq 1 ]];then
    # c++/c
    vim -c ":CocInstall coc-clangd" -c ":q"
    
    # Install clangd
    if [ ! -x "$(command -v clangd)" ];then
        cd /tmp/ && git clone -b llvmorg-12.0.1 https://gitee.com/mirrors/LLVM.git && \
            cd LLVM && \
            mkdir build && cd build && \
            cmake -G "Unix Makefiles" -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-12.0.1 -DCMAKE_BUILD_TYPE=Release ../llvm && \
            make -j$(nproc) && \
            sudo make install
    
    fi
fi

# typescript
vim -c ":CocInstall coc-tsserver" -c ":q"


if [[ $ENABLE_SYMBOL -eq 1 ]];then
    # Install global and ctags
    source /etc/os-release
    
    case $ID in
    debian|ubuntu)
        sudo apt install \
        gcc make \
        pkg-config autoconf automake \
        python3-docutils \
        libseccomp-dev \
        libjansson-dev \
        libyaml-dev \
        libxml2-dev
        ;;
    centos|rhel)
        sudo yum install \
        gcc make \
        pkgconfig autoconf automake \
        python-docutils \
        libseccomp-devel \
        jansson-devel \
        libyaml-devel \
        libxml2-devel
        ;;
    *)
        exit 1
        ;;
    esac
    
    wget https://ftp.gnu.org/pub/gnu/global/global-6.6.5.tar.gz -O /tmp/global-6.6.5.tar.gz && \
        cd /tmp/ && tar -xvf global-6.6.5.tar.gz && cd global-6.6.5 && \
        sh reconf.sh && ./configure && make -j$(nproc) && sudo make install  && \
        cd - && rm -rf /tmp/global-6.6.5*
    
    git clone https://github.com/universal-ctags/ctags.git /tmp/ctags && \
        cd /tmp/ctags && \
        ./autogen.sh && \
        ./configure && make -j$(nproc) && sudo make install && \
        cd - && rm -rf /tmp/ctags*
fi
    

if [[ $ENABLE_RG -eq 1 ]];then
    # Install ripgrep
    source /etc/os-release
    
    case $ID in
    debian|ubuntu)
        sudo apt-get install ripgrep
        ;;
    centos|rhel)
        sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
        sudo yum install ripgrep
        ;;
    *)
        exit 1
        ;;
    esac
fi
