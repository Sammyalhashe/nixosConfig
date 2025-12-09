#!/bin/sh

# This script installs the Nix package manager on your system by
# downloading a binary distribution and running its installer script
# (which in turn creates and populates /nix).

{ # Prevent execution if this script was only partially downloaded
oops() {
    echo "$0:" "$@" >&2
    exit 1
}

umask 0022

tmpDir="$(mktemp -d -t nix-binary-tarball-unpack.XXXXXXXXXX || \
          oops "Can't create temporary directory for downloading the Nix binary tarball")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        hash=0737755f3106e8dffbf26a77af398888e8421974b91fe2b86052c891f71e16b5
        path=cp85f1ak1aww5gbaj474w8rgvkj0nidi/nix-2.32.4-x86_64-linux.tar.xz
        system=x86_64-linux
        ;;
    Linux.i?86)
        hash=a7b28b6144cd1d438dbf8d89a9cf3d614c11f7493f81c1830a99bc8daae43d1d
        path=ndbgicakygnnml69r29nqn2whxrkgr8b/nix-2.32.4-i686-linux.tar.xz
        system=i686-linux
        ;;
    Linux.aarch64)
        hash=ee8541c595a283079a52ca14b1db7f88f2d927d6f46b61bcede5abfb104e5b57
        path=ap7fbbm31w9xd131hj7bb9d2nfxq30k6/nix-2.32.4-aarch64-linux.tar.xz
        system=aarch64-linux
        ;;
    Linux.armv6l)
        hash=6d2d7b0efab456b83e11bf246e4f1c97b1d7db99bf368ee820097ec5bfd2eae0
        path=5n1c1llpz40q0q5hsjb3nylj1a13c44q/nix-2.32.4-armv6l-linux.tar.xz
        system=armv6l-linux
        ;;
    Linux.armv7l)
        hash=13a97cdf6abf7d864a215c4a098e4e3644802a4dcb42ec176acea9531fba2b1f
        path=8llv3935a12x12vdrxgdax01i2pqklvl/nix-2.32.4-armv7l-linux.tar.xz
        system=armv7l-linux
        ;;
    Linux.riscv64)
        hash=be62d66966ac8e08b664bba748e31ec9ad5cc73edc69766794728ac02e4e0f73
        path=qwkciyhb8kp44l93rz5p5sdjhc11b4dd/nix-2.32.4-riscv64-linux.tar.xz
        system=riscv64-linux
        ;;
    Darwin.x86_64)
        hash=140454e17ba481e4b1292417192dc664c613695ee2e5350e72bd13a2607e12b5
        path=442k6y40chrxx7m0rqlrgcmgdfvk9af4/nix-2.32.4-x86_64-darwin.tar.xz
        system=x86_64-darwin
        ;;
    Darwin.arm64|Darwin.aarch64)
        hash=073c1f99d372492264601b78f5794b5db418d0654370b47f39d24aeb6cc1a7e6
        path=h6fkcd48cj9ycp1p9vgjb5kdllcjsqvs/nix-2.32.4-aarch64-darwin.tar.xz
        system=aarch64-darwin
        ;;
    *) oops "sorry, there is no binary distribution of Nix for your platform";;
esac

# Use this command-line option to fetch the tarballs using nar-serve or Cachix
if [ "${1:-}" = "--tarball-url-prefix" ]; then
    if [ -z "${2:-}" ]; then
        oops "missing argument for --tarball-url-prefix"
    fi
    url=${2}/${path}
    shift 2
else
    url=https://releases.nixos.org/nix/nix-2.32.4/nix-2.32.4-$system.tar.xz
fi

tarball=$tmpDir/nix-2.32.4-$system.tar.xz

require_util tar "unpack the binary tarball"
if [ "$(uname -s)" != "Darwin" ]; then
    require_util xz "unpack the binary tarball"
fi

if command -v curl > /dev/null 2>&1; then
    fetch() { curl --fail -L "$1" -o "$2"; }
elif command -v wget > /dev/null 2>&1; then
    fetch() { wget "$1" -O "$2"; }
else
    oops "you don't have wget or curl installed, which I need to download the binary tarball"
fi

echo "downloading Nix 2.32.4 binary tarball for $system from '$url' to '$tmpDir'..."
fetch "$url" "$tarball" || oops "failed to download '$url'"

if command -v sha256sum > /dev/null 2>&1; then
    hash2="$(sha256sum -b "$tarball" | cut -c1-64)"
elif command -v shasum > /dev/null 2>&1; then
    hash2="$(shasum -a 256 -b "$tarball" | cut -c1-64)"
elif command -v openssl > /dev/null 2>&1; then
    hash2="$(openssl dgst -r -sha256 "$tarball" | cut -c1-64)"
else
    oops "cannot verify the SHA-256 hash of '$url'; you need one of 'shasum', 'sha256sum', or 'openssl'"
fi

if [ "$hash" != "$hash2" ]; then
    oops "SHA-256 hash mismatch in '$url'; expected $hash, got $hash2"
fi

unpack=$tmpDir/unpack
mkdir -p "$unpack"
tar -xJf "$tarball" -C "$unpack" || oops "failed to unpack '$url'"

script=$(echo "$unpack"/*/install)

[ -e "$script" ] || oops "installation script is missing from the binary tarball!"
export INVOKED_FROM_INSTALL_IN=1
"$script" "$@"

} # End of wrapping
