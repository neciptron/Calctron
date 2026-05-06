#!/bin/bash
set -e

echo "========================================="
echo "  Calctron - Installation Script"
echo "========================================="
echo ""

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "Detected: $OS ($ARCH)"
echo ""

# Zig version to install
ZIG_VERSION="0.16.0"

# Determine Zig download URL
if [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    elif [ "$ARCH" = "aarch64" ]; then
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-aarch64-${ZIG_VERSION}.tar.xz"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-macos-x86_64-${ZIG_VERSION}.tar.xz"
    elif [ "$ARCH" = "arm64" ]; then
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-macos-aarch64-${ZIG_VERSION}.tar.xz"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]] || [[ "$OS" == CYGWIN* ]]; then
    echo "Windows detected. Please download Zig manually from:"
    echo "  https://ziglang.org/download/"
    exit 1
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Check if Zig is already installed
if command -v zig &> /dev/null; then
    CURRENT_ZIG=$(zig version 2>/dev/null || echo "unknown")
    echo "Zig already installed: $CURRENT_ZIG"
    echo ""
fi

# Install Zig if not found
if ! command -v zig &> /dev/null; then
    echo "Downloading Zig ${ZIG_VERSION}..."
    echo "  URL: $ZIG_URL"
    echo ""

    INSTALL_DIR="${HOME}/.local"
    mkdir -p "$INSTALL_DIR"

    TEMP_FILE="/tmp/zig-${ZIG_VERSION}.tar.xz"
    wget -q "$ZIG_URL" -O "$TEMP_FILE" || curl -sL "$ZIG_URL" -o "$TEMP_FILE"

    echo "Extracting..."
    tar -xf "$TEMP_FILE" -C "$INSTALL_DIR"
    rm "$TEMP_FILE"

    # Add to PATH
    ZIG_BIN="$INSTALL_DIR/zig-linux-${ARCH}-${ZIG_VERSION}"
    if [ "$OS" = "Darwin" ]; then
        ZIG_BIN="$INSTALL_DIR/zig-macos-${ARCH}-${ZIG_VERSION}"
    fi

    echo ""
    echo "Zig installed to: $ZIG_BIN"
    echo ""
    echo "Add to your PATH by running:"
    echo "  echo 'export PATH=\"${ZIG_BIN}:\$PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo ""
    echo "Or for this session:"
    echo "  export PATH=\"${ZIG_BIN}:\$PATH\""
    echo ""

    export PATH="${ZIG_BIN}:$PATH"
fi

echo "Zig version: $(zig version)"
echo ""

# Install raylib dependencies
echo "Installing raylib system dependencies..."
if [ "$OS" = "Linux" ]; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            libgl1-mesa-dev \
            libx11-dev \
            libxrandr-dev \
            libxinerama-dev \
            libxcursor-dev \
            libxi-dev \
            libxext-dev \
            libxfixes-dev \
            wayland-protocols \
            libwayland-dev \
            libxkbcommon-dev \
            2>/dev/null || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y \
            mesa-libGL-devel \
            libX11-devel \
            libXrandr-devel \
            libXinerama-devel \
            libXcursor-devel \
            libXi-devel \
            libXext-devel \
            libXfixes-devel \
            2>/dev/null || true
    fi
elif [ "$OS" = "Darwin" ]; then
    echo "macOS - no additional dependencies needed (uses native frameworks)"
fi

echo ""
echo "Dependencies installed."
echo ""

# Fetch raylib-zig dependency
echo "Fetching raylib-zig dependency..."
cd "$(dirname "$0")"
zig fetch --save "https://github.com/raylib-zig/raylib-zig/archive/refs/tags/v5.6-dev.tar.gz" 2>/dev/null || true

echo ""
echo "========================================="
echo "  Build the project:"
echo "    zig build"
echo ""
echo "  Run the calculator:"
echo "    zig build run"
echo ""
echo "  Run tests:"
echo "    zig build test"
echo "========================================="
