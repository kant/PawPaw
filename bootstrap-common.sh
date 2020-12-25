#!/bin/bash

set -e

cd $(dirname ${0})
PAWPAW_ROOT="${PWD}"

# ---------------------------------------------------------------------------------------------------------------------

target="${1}"

if [ -z "${target}" ]; then
    echo "usage: ${0} <target>"
    exit 1
fi

# ---------------------------------------------------------------------------------------------------------------------

# TODO check for depedencies:
# - curl
# - cmake
# - make
# - jq
# - patch
# - python (waf, meson)
# - sed
# - tar

source setup/check_target.sh
source setup/env.sh
source setup/functions.sh
source setup/versions.sh

mkdir -p "${PAWPAW_BUILDDIR}"
mkdir -p "${PAWPAW_DOWNLOADDIR}"
mkdir -p "${PAWPAW_PREFIX}"
mkdir -p "${PAWPAW_TMPDIR}"

# ---------------------------------------------------------------------------------------------------------------------
# let's use native glib for linux builds

if [ "${LINUX}" -eq 1 ] && [ ! -e "${TARGET_PKG_CONFIG_PATH}/glib-2.0.pc" ]; then
    mkdir -p ${TARGET_PKG_CONFIG_PATH}
    ln -s $(pkg-config --variable=pcfiledir glib-2.0)/g{io,lib,module,object,thread}-2.0.pc ${TARGET_PKG_CONFIG_PATH}/
    ln -s $(pkg-config --variable=pcfiledir libpcre)/libpcre.pc ${TARGET_PKG_CONFIG_PATH}/
fi

# ---------------------------------------------------------------------------------------------------------------------
# pkgconfig

download pkg-config "${PKG_CONFIG_VERSION}" "https://pkg-config.freedesktop.org/releases"
build_host_autoconf pkg-config "${PKG_CONFIG_VERSION}" "--enable-indirect-deps --with-internal-glib --with-pc-path=${TARGET_PKG_CONFIG_PATH}"

# ---------------------------------------------------------------------------------------------------------------------
# libogg

download libogg "${LIBOGG_VERSION}" "https://ftp.osuosl.org/pub/xiph/releases/ogg"
patch_file libogg "${LIBOGG_VERSION}" "include/ogg/os_types.h" 's/__MACH__/__MACH_SKIP__/'
build_autoconf libogg "${LIBOGG_VERSION}"

# ---------------------------------------------------------------------------------------------------------------------
# libvorbis

download libvorbis "${LIBVORBIS_VERSION}" "https://ftp.osuosl.org/pub/xiph/releases/vorbis"
build_autoconf libvorbis "${LIBVORBIS_VERSION}" "--disable-examples"

# ---------------------------------------------------------------------------------------------------------------------
# flac

FLAC_EXTRAFLAGS="--disable-doxygen-docs --disable-examples --disable-thorough-tests --disable-xmms-plugin"

if [ "${MACOS_OLD}" -eq 1 ]; then
    FLAC_EXTRAFLAGS="${FLAC_EXTRAFLAGS} --disable-asm-optimizations"
elif [ "${MACOS_UNIVERSAL}" -eq 1 ]; then
    FLAC_EXTRAFLAGS="${FLAC_EXTRAFLAGS} ac_cv_header_x86intrin_h=yes asm_opt=yes"
fi

download flac "${FLAC_VERSION}" "https://ftp.osuosl.org/pub/xiph/releases/flac" "tar.xz"
patch_file flac "${FLAC_VERSION}" "configure" 's/amd64|x86_64/amd64|arm|x86_64/'
build_autoconf flac "${FLAC_VERSION}" "${FLAC_EXTRAFLAGS}"

# ---------------------------------------------------------------------------------------------------------------------
# libsamplerate

download libsamplerate "${LIBSAMPLERATE_VERSION}" "http://www.mega-nerd.com/SRC"
build_autoconf libsamplerate "${LIBSAMPLERATE_VERSION}" "--disable-fftw --disable-sndfile"

# ---------------------------------------------------------------------------------------------------------------------
# libsndfile

download libsndfile "${LIBSNDFILE_VERSION}" "http://www.mega-nerd.com/libsndfile/files"
patch_file libsndfile "${LIBSNDFILE_VERSION}" "configure" 's/ -Wvla//'
build_autoconf libsndfile "${LIBSNDFILE_VERSION}" "--disable-full-suite --disable-alsa --disable-sqlite"

# ---------------------------------------------------------------------------------------------------------------------
