#!/bin/sh
# Builds the Etesian widget style into look/style/build/etesian.so: here with cmake and the Qt 6 development files, otherwise in
# a throwaway Kubuntu 26.04 container (Docker), as look/decoration/build.sh. Nothing is installed by this script.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
if command -v cmake >/dev/null && [ -d /usr/lib/x86_64-linux-gnu/cmake/Qt6Widgets -o -d /usr/lib/cmake/Qt6Widgets ]; then
  cmake -S "$here" -B "$here/build" -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build "$here/build" -j"$(nproc)"
else
  command -v docker >/dev/null || { echo "Needs cmake + qt6-base-dev (or Docker) to build the style" >&2; exit 1; }
  docker run --rm -v "$here:/src" -w /src "${ETESIAN_BUILD_IMAGE:-ubuntu:26.04}" sh -c '
    apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cmake g++ qt6-base-dev >/dev/null &&
    cmake -S /src -B /tmp/b -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /tmp/b -j"$(nproc)" &&
    mkdir -p /src/build && cp /tmp/b/etesian.so /src/build/ && chown -R '"$(id -u):$(id -g)"' /src/build'
fi
ls -l "$here/build/etesian.so"
