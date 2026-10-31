#!/bin/sh
# Builds the Etesian mail plugin (the KMail source of the Belle Mail widget) into look/mail/build/org/etesian/mail.
# With cmake and the Akonadi development files here, it builds here; otherwise in a throwaway Kubuntu 26.04 container
# (Docker). Nothing is installed by this script.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
if command -v cmake >/dev/null && [ -d /usr/lib/x86_64-linux-gnu/cmake/KPim6Akonadi -o -d /usr/lib/cmake/KPim6Akonadi ]; then
  cmake -S "$here" -B "$here/build" -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build "$here/build" -j"$(nproc)"
else
  command -v docker >/dev/null || { echo "Needs cmake + the Akonadi development files (or Docker) to build the mail plugin" >&2; exit 1; }
  docker run --rm -v "$here:/src" -w /src "${ETESIAN_BUILD_IMAGE:-ubuntu:26.04}" sh -c '
    if ! [ -d /usr/lib/x86_64-linux-gnu/cmake/KPim6Akonadi ]; then apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq cmake g++ extra-cmake-modules qt6-base-dev qt6-declarative-dev libakonadi-dev libakonadimime-dev libkmime-dev >/dev/null; fi &&
    cmake -S /src -B /tmp/b -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /tmp/b -j"$(nproc)" &&
    rm -rf /src/build && mkdir -p /src/build/org/etesian && cp -r /tmp/b/org/etesian/mail /src/build/org/etesian/ && chown -R '"$(id -u):$(id -g)"' /src/build'
fi
ls -l "$here/build/org/etesian/mail"
