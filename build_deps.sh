#!/bin/bash
# -----------------------------------------------------------------------------
# build_deps.sh
#
# Builds and installs all non-ROS dependencies for ricoh_theta_ros.
#
# Requirements: git, wget, build-essential, cmake, libjpeg-dev,
#               gstreamer1.0 dev packages, linux-headers-$(uname -r)
#
# Usage:
#   ./build_deps.sh
#
# After successful build, add the following to your ~/.bashrc or ~/.zshrc:
#   export PATH="$(pwd)/deps/install/bin:$PATH"
#   export LD_LIBRARY_PATH="$(pwd)/deps/install/lib:$LD_LIBRARY_PATH"
#   export PKG_CONFIG_PATH="$(pwd)/deps/install/lib/pkgconfig:$PKG_CONFIG_PATH"
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INSTALL_PREFIX="$SCRIPT_DIR/deps/install"
mkdir -p "$INSTALL_PREFIX"/{bin,lib,include,pkgconfig}

NUM_JOBS=$(nproc)

# Helper: install apt packages with fallback
_install_apt() {
    sudo apt-get update || true
    sudo apt-get install -y "$@" || true
}

echo "=== Installing APT build dependencies ==="
_install_apt \
    build-essential \
    cmake \
    libjpeg-dev \
    libusb-0.1-4 \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    libgstreamer-plugins-base1.0-dev \
    linux-headers-"$(uname -r)"

# libptp requires libusb-0.1 headers. On modern Ubuntu the old libusb-dev
# package may be missing, so we build libusb-compat-0.1 from source if needed.
if [ ! -f /usr/include/usb.h ]; then
    echo "=== libusb-0.1 headers missing, building libusb-compat-0.1 from source ==="
    cd "$SCRIPT_DIR"
    if [ ! -f "libusb-compat-0.1.8.tar.bz2" ]; then
        wget -q --show-progress \
            "https://sourceforge.net/projects/libusb/files/libusb-compat-0.1/libusb-compat-0.1.8.tar.bz2/download" \
            -O libusb-compat-0.1.8.tar.bz2 \
            || wget -q --show-progress \
                "https://github.com/libusb/libusb-compat-0.1/releases/download/v0.1.8/libusb-compat-0.1.8.tar.bz2" \
                -O libusb-compat-0.1.8.tar.bz2
    fi
    rm -rf libusb-compat-0.1
    tar xjf libusb-compat-0.1.8.tar.bz2
    cd libusb-compat-0.1.8
    ./configure --prefix="$INSTALL_PREFIX"
    make -j${NUM_JOBS}
    make install
    cd "$SCRIPT_DIR"
fi

# Export local prefix so downstream builds can find our custom libusb-compat
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LDFLAGS="-L$INSTALL_PREFIX/lib ${LDFLAGS:-}"
export CPPFLAGS="-I$INSTALL_PREFIX/include ${CPPFLAGS:-}"

echo "=== Building libptp ==="
cd "$SCRIPT_DIR/deps/libptp"
if [ ! -x configure ]; then
    ./autogen.sh
fi
./configure --prefix="$INSTALL_PREFIX"
make -j${NUM_JOBS}
make install

echo "=== Building libuvc-theta ==="
cd "$SCRIPT_DIR/deps/libuvc-theta"
git checkout theta_uvc 2>/dev/null || true
mkdir -p build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release
make -j${NUM_JOBS}
make install

echo "=== Building libuvc-theta-sample ==="
cd "$SCRIPT_DIR/deps/libuvc-theta-sample/gst"
make clean 2>/dev/null || true
make
cp -v gst_view "$INSTALL_PREFIX/bin/"
if [ -f gst_loopback ]; then
    cp -v gst_loopback "$INSTALL_PREFIX/bin/"
else
    ln -sf gst_view "$INSTALL_PREFIX/bin/gst_loopback"
fi

echo "=== Building v4l2loopback ==="
cd "$SCRIPT_DIR/deps/v4l2loopback"
make clean 2>/dev/null || true
make
sudo make install
sudo depmod -a

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "Add the following lines to your shell rc file (~/.bashrc or ~/.zshrc):"
echo ""
echo "  export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
echo "  export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""
echo "  export PKG_CONFIG_PATH=\"$INSTALL_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""
echo ""
echo "Then run: source ~/.bashrc"
echo ""
echo "Binaries are installed in:"
echo "  $INSTALL_PREFIX/bin"
echo ""
echo "To start the camera, make sure the v4l2loopback module is loaded:"
echo "  sudo modprobe v4l2loopback video_nr=2"
echo ""
echo "Then run the startup script:"
echo "  ros2 run ricoh_theta_ros start.sh"
