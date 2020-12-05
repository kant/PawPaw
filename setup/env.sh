#!/bin/bash

# ---------------------------------------------------------------------------------------------------------------------
# OS setup

if [ "${LINUX}" -eq 1 ]; then
    CMAKE_SYSTEM_NAME="Linux"
    PAWPAW_TARGET="linux"

elif [ "${MACOS}" -eq 1 ]; then
    CMAKE_SYSTEM_NAME="Darwin"
    if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
        PAWPAW_TARGET="macos-universal"
    elif [ "${MACOS_OLD}" -eq 1 ]; then
        PAWPAW_TARGET="macos-old"
    else
        PAWPAW_TARGET="macos"
    fi

elif [ "${WIN32}" -eq 1 ]; then
    CMAKE_SYSTEM_NAME="Windows"
    if [ "${WIN64}" -eq 1 ]; then
        PAWPAW_TARGET="win64"
    else
        PAWPAW_TARGET="win32"
    fi

else
    echo "Unknown target '${target}'"
    exit 4
fi

# ---------------------------------------------------------------------------------------------------------------------
# PawPaw setup

PAWPAW_DIR="${HOME}/PawPawBuilds"
PAWPAW_DOWNLOADDIR="${PAWPAW_DIR}/downloads"
PAWPAW_BUILDDIR="${PAWPAW_DIR}/builds/${PAWPAW_TARGET}"
PAWPAW_PREFIX="${PAWPAW_DIR}/targets/${PAWPAW_TARGET}"
PAWPAW_TMPDIR="/tmp"

# ---------------------------------------------------------------------------------------------------------------------
# build environment

## build flags

BUILD_FLAGS="-O2 -pipe -I${PAWPAW_PREFIX}/include"
BUILD_FLAGS="${BUILD_FLAGS} -mtune=generic -msse -msse2 -ffast-math"
BUILD_FLAGS="${BUILD_FLAGS} -fPIC -DPIC -DNDEBUG -D_FORTIFY_SOURCE=2"
BUILD_FLAGS="${BUILD_FLAGS} -fdata-sections -ffunction-sections -fno-common -fstack-protector -fvisibility=hidden"

if [ "${MACOS_UNIVERSAL}" -ne 1 ]; then
    BUILD_FLAGS="${BUILD_FLAGS} -mfpmath=sse"
fi

if [ "${MACOS}" -eq 1 ]; then
    if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
        BUILD_FLAGS="${BUILD_FLAGS} -mmacosx-version-min=10.12 -arch x86_64 -arch arm64"
    elif [ "${MACOS_OLD}" -eq 1 ]; then
        BUILD_FLAGS="${BUILD_FLAGS} -mmacosx-version-min=10.5"
    else
        BUILD_FLAGS="${BUILD_FLAGS} -mmacosx-version-min=10.8 -stdlib=libc++ -Wno-deprecated-declarations"
    fi
elif [ "${WIN32}" -eq 1 ]; then
    BUILD_FLAGS="${BUILD_FLAGS} -DPTW32_STATIC_LIB -mstackrealign"
fi
# -DFLUIDSYNTH_NOT_A_DLL

TARGET_CFLAGS="${BUILD_FLAGS}"
TARGET_CXXFLAGS="${BUILD_FLAGS} -fvisibility-inlines-hidden"

## link flags

LINK_FLAGS="-L${PAWPAW_PREFIX}/lib"
LINK_FLAGS="${LINK_FLAGS} -fdata-sections -ffunction-sections -fstack-protector"

if [ "${MACOS}" -eq 1 ]; then
    LINK_FLAGS="${LINK_FLAGS} -Wl,-dead_strip -Wl,-dead_strip_dylibs"

    if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
        LINK_FLAGS="${LINK_FLAGS} -mmacosx-version-min=10.12 -arch x86_64 -arch arm64"
    elif [ "${MACOS_OLD}" -eq 1 ]; then
        LINK_FLAGS="${LINK_FLAGS} -mmacosx-version-min=10.5"
        # LINK_FLAGS="${LINK_FLAGS} -L/usr/lib/apple/SDKs/MacOSX10.5.sdk/usr/lib"
    else
        LINK_FLAGS="${LINK_FLAGS} -mmacosx-version-min=10.8 -stdlib=libc++"
    fi
else
    LINK_FLAGS="${LINK_FLAGS} -Wl,-O1 -Wl,--as-needed -Wl,--gc-sections -Wl,--no-undefined -Wl,--strip-all"
    if [ "${WIN32}" -eq 1 ]; then
        LINK_FLAGS="${LINK_FLAGS} -static -lssp_nonshared -Wl,-Bstatic"
    fi
fi

TARGET_LDFLAGS="${LINK_FLAGS}"

## toolchain

if [ "${CROSS_COMPILING}" -eq 1 ]; then
    if [ "${MACOS}" -eq 1 ]; then
        TOOLCHAIN_PREFIX="i686-apple-darwin10"
        TOOLCHAIN_PREFIX_="${TOOLCHAIN_PREFIX}-"
    elif [ "${WIN64}" -eq 1 ]; then
        TOOLCHAIN_PREFIX="x86_64-w64-mingw32"
        TOOLCHAIN_PREFIX_="${TOOLCHAIN_PREFIX}-"
    elif [ "${WIN32}" -eq 1 ]; then
        TOOLCHAIN_PREFIX="i686-w64-mingw32"
        TOOLCHAIN_PREFIX_="${TOOLCHAIN_PREFIX}-"
    fi
fi

TARGET_AR="${TOOLCHAIN_PREFIX_}ar"
TARGET_CC="${TOOLCHAIN_PREFIX_}gcc"
TARGET_CXX="${TOOLCHAIN_PREFIX_}g++"
TARGET_LD="${TOOLCHAIN_PREFIX_}ld"
TARGET_STRIP="${TOOLCHAIN_PREFIX_}strip"
TARGET_PATH="${PAWPAW_PREFIX}/bin:/usr/${TOOLCHAIN_PREFIX}/bin:${PATH}"
TARGET_PKG_CONFIG="${PAWPAW_PREFIX}/bin/pkg-config --static"
TARGET_PKG_CONFIG_PATH="${PAWPAW_PREFIX}/lib/pkgconfig"

# ---------------------------------------------------------------------------------------------------------------------
# other

MAKE_ARGS=""
WAF_ARGS=""

if which nproc > /dev/null; then
    MAKE_ARGS+="-j $(nproc)"
    WAF_ARGS+="-j $(nproc)"
fi

if [ "${CROSS_COMPILING}" -eq 1 ]; then
    MAKE_ARGS="${MAKE_ARGS} CROSS_COMPILING=true"
fi

if [ "${MACOS}" -eq 1 ]; then
    MAKE_ARGS="${MAKE_ARGS} MACOS=true"
    if [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
        MAKE_ARGS="${MAKE_ARGS} MACOS_UNIVERSAL=true"
    elif [ "${MACOS_OLD}" -eq 1 ]; then
        MAKE_ARGS="${MAKE_ARGS} MACOS_OLD=true"
    fi
elif [ "${WIN32}" -eq 1 ]; then
    MAKE_ARGS="${MAKE_ARGS} WIN32=true WINDOWS=true"
fi

# ---------------------------------------------------------------------------------------------------------------------
