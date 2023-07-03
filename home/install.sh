#!/usr/bin/env bash
set -e

while true; do
    ping -c 1 8.8.8.8 && break
    sleep 1
done

echo "#### checking install progress ####"
if [ ! -f "/data/data/com.termux/files/home/.install_progress" ]
then
  echo 0 > /data/data/com.termux/files/home/.install_progress
fi
SET_STAGE=`cat /data/data/com.termux/files/home/.install_progress`

# mount -o remount,rw /system

# setup directory for apt cache
if [ ! -d "/data/data/com.termux/cache/apt/archives/partial" ]
then
  mkdir -p /data/data/com.termux/cache/apt/archives/partial
fi

# prevent apt from updating
echo "apt hold" | dpkg --set-selections

# setup the env
apt-get update
apt-get install gawk findutils
chmod 644 /data/data/com.termux/files/home/.ssh/config
chown root:root /data/data/com.termux/files/home/.ssh/config

# Execute all apt postinstall scripts
chmod +x /usr/var/lib/dpkg/info/*.postinst
find /usr/var/lib/dpkg/info -type f  -executable -exec sh -c 'exec "$1"' _ {} \;
chmod +x /usr/var/lib/dpkg/info/*.prerm

if [ -d "/tmp/build" ] 
then
  rm -rf /tmp/build/
fi

mkdir /tmp/build
cd /tmp/build

if [ $SET_STAGE -lt 1 ]; then

  # new apt stuff
  # tur repo
  apt install -y tur-repo

  # -------- GCC
  # mkdir gcc
  # pushd gcc

  # BINUTILS=binutils-2.32
  # GCC=gcc-4.7.1
  # PREFIX=/usr

  # mkdir src
  # pushd src
  # wget --tries=inf ftp://ftp.gnu.org/gnu/binutils/$BINUTILS.tar.bz2
  # tar -xf $BINUTILS.tar.bz2
  # popd
  
  # mkdir -p build/$BINUTILS
  # pushd build/$BINUTILS

  # # hack for binutils
  # sed -i '1s/^/#define __ANDROID_API__ 28\n/' ../../src/$BINUTILS/bfd/bfdio.c

  # ../../src/$BINUTILS/configure CPPFLAGS="-D__ANDROID_API__=28" --target=arm-none-eabi \
  #   --build=aarch64-unknown-linux-gnu \
  #   --prefix=$PREFIX --with-cpu=cortex-m4 \
  #   --with-mode=thumb \
  #   --disable-nls \
  #   --disable-werror
  # make -j4 all
  # make install
  # popd

  # mkdir -p src
  # pushd src
  # wget --tries=inf ftp://ftp.gnu.org/gnu/gcc/$GCC/$GCC.tar.bz2
  # tar -xf $GCC.tar.bz2
  # cd $GCC
  # contrib/download_prerequisites
  # popd

  # export PATH="$PREFIX/bin:$PATH"

  # mkdir -p build/$GCC
  # pushd build/$GCC
  # ../../src/$GCC/configure --target=arm-none-eabi \
  #   --build=aarch64-unknown-linux-gnu \
  #   --disable-libssp --disable-gomp --disable-libstcxx-pch --enable-threads \
  #   --disable-shared --disable-libmudflap \
  #   --prefix=$PREFIX --with-cpu=cortex-m4 \
  #   --with-mode=thumb --disable-multilib \
  #   --enable-interwork \
  #   --enable-languages="c" \
  #   --disable-nls \
  #   --disable-libgcc
  # make -j4 all-gcc
  # make install-gcc
  # popd

  apt install -y gcc-9
  apt install -y binutils

  echo "2" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=1
fi

if [ $SET_STAGE -lt 2 ]; then
  # replace stdint.h with stdint-gcc.h for Android compatibility
  # mv $PREFIX/lib/gcc/arm-none-eabi/4.7.1/include/stdint-gcc.h $PREFIX/lib/gcc/arm-none-eabi/4.7.1/include/stdint.h

  # popd

  # -------- capnproto
  # VERSION=0.8.0

  # wget --tries=inf https://capnproto.org/capnproto-c++-${VERSION}.tar.gz
  # tar xvf capnproto-c++-${VERSION}.tar.gz

  # pushd capnproto-c++-${VERSION}

  # CXXFLAGS="-fPIC -O2" ./configure --prefix=/usr
  # make -j4 install
  # popd
  apt install capnproto
  echo "3" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=2
fi

if [ $SET_STAGE -lt 3 ]; then
  # ---- Eigen
  wget --tries=inf https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.tar.bz2
  mkdir eigen
  tar xjf eigen-3.3.7.tar.bz2
  pushd eigen-3.3.7
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=/usr ..
  make install
  popd
  echo "4" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=3
fi

if [ $SET_STAGE -lt 4 ]; then
  # --- Libusb
  wget --tries=inf https://github.com/libusb/libusb/releases/download/v1.0.22/libusb-1.0.22.tar.bz2
  tar xjf libusb-1.0.22.tar.bz2
  pushd libusb-1.0.22
  ./configure --prefix=/usr --disable-udev
  make -j4
  make install
  popd
  echo "5" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=4
fi

if [ $SET_STAGE -lt 5 ]; then
  # ------- tcpdump
  # VERSION="4.9.2"
  # wget --tries=inf https://www.tcpdump.org/release/tcpdump-$VERSION.tar.gz
  # tar xvf tcpdump-$VERSION.tar.gz
  # pushd tcpdump-$VERSION
  # ./configure --prefix=/usr
  # make -j4
  # make install
  # popd
  apt install tcpdump
  echo "6" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=5
fi

if [ $SET_STAGE -lt 6 ]; then
  # ----- DFU util 0.8
  wget --tries=inf http://dfu-util.sourceforge.net/releases/dfu-util-0.8.tar.gz
  tar xvf dfu-util-0.8.tar.gz
  pushd dfu-util-0.8
  ./configure --prefix=/usr
  make -j4
  make install
  popd
  echo "7" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=6
fi

if [ $SET_STAGE -lt 7 ]; then
  # ----- Nload
  wget --tries=inf -O nload-v0.7.4.tar.gz https://github.com/rolandriegel/nload/archive/v0.7.4.tar.gz
  tar xvf nload-v0.7.4.tar.gz
  pushd nload-0.7.4
  bash run_autotools
  ./configure --prefix=/usr
  make -j4
  make install
  popd
  echo "8" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=7
fi
if [ $SET_STAGE -lt 8 ]; then
  # ------- python packages
  cd $HOME
  export PYCURL_SSL_LIBRARY=openssl
  # pip install --no-cache-dir --upgrade pip
  # pip install --no-cache-dir pipenv
  # pipenv install --deploy --system --verbose --clear
  # numpy and scipy
  apt install -y python-numpy python-scipy
  pip install -r requirements.txt
  echo "9" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=8
fi
if [ $SET_STAGE -lt 9 ]; then
  # ------- casadi
  cd /tmp/build
  git clone https://github.com/casadi/casadi.git
  pushd casadi
  git fetch --all --tags
  git checkout tags/3.5.5
  sed -i "s/target_link_libraries(_casadi casadi)/target_link_libraries(_casadi $\{PYTHON_LIBRARIES} casadi)/g" swig/python/CMakeLists.txt

  mkdir -p build
  cd build
  cmake -DWITH_PYTHON=ON \
        -DWITH_PYTHON3=ON \
        -DWITH_DEEPBIND=OFF \
        -DWITH_DOC=OFF \
        -DWITH_EXAMPLES=OFF \
        -DLIB_PREFIX=/usr/lib \
        -DINCLUDE_PREFIX=/usr/include \
        ..
  make -j4
  make install
  rm -rf /usr/local/
  python -c "from casadi import *"
  popd
  echo "10" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=9
fi

if [ $SET_STAGE -lt 10 ]; then
  # ------- OpenCV
  # cd /tmp/build
  # git clone https://github.com/opencv/opencv.git
  # git -C opencv checkout 4.x
  # mkdir -p build 
  # cd build
  # cmake ../opencv -DCMAKE_CXX_FLAGS="-llog" 
  # make -j4
  # make install
  echo "11" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=10
fi

if [ $SET_STAGE -lt 11 ]; then
  echo "\n\nInstall successful\nTook $SECONDS seconds" > /data/data/com.termux/files/retros_setup_complete
  echo "12" > /data/data/com.termux/files/home/.install_progress
  SET_STAGE=11
fi
