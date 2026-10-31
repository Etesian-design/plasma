#!/bin/sh
# Builds the Etesian decoration plugin into look/decoration/build/org.etesian.decoration.so.
# With cmake and the KDecoration3 development files here, it builds here; otherwise in a throwaway Kubuntu 26.04 container
# (Docker), which matches Plasma 6.6. Nothing is installed by this script.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
if command -v cmake >/dev/null && [ -d /usr/lib/x86_64-linux-gnu/cmake/KDecoration3 -o -d /usr/lib/cmake/KDecoration3 ]; then
  cmake -S "$here" -B "$here/build" -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build "$here/build" -j"$(nproc)"
else
  command -v docker >/dev/null || { echo "Needs cmake + libkdecorations3-dev (or Docker) to build the decoration" >&2; exit 1; }
  docker run --rm -v "$here:/src" -w /src "${ETESIAN_BUILD_IMAGE:-ubuntu:26.04}" sh -c '
    apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cmake g++ extra-cmake-modules qt6-base-dev libkdecorations3-dev libkf6coreaddons-dev >/dev/null &&
    cmake -S /src -B /tmp/b -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /tmp/b -j"$(nproc)" &&
    mkdir -p /src/build && cp /tmp/b/org.etesian.decoration.so /tmp/b/kdecoration-version /src/build/ && chown -R '"$(id -u):$(id -g)"' /src/build'
fi
ls -l "$here/build/org.etesian.decoration.so"
