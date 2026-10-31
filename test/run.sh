#!/bin/bash
# Runs a test scenario in a throwaway Plasma container: test/run.sh <scenario> [ubuntu]. Screenshots land in test/out/.
# Needs Docker and a GPU render node (/dev/dri/renderD128): without OpenGL, KWin cannot take screenshots.
set -e
cd "$(dirname "$0")/.."
scenario="${1:?scenario name, see test/scenarios}"; distro="${2:-ubuntu}"
image="etesian-plasma-test:$distro"
docker build -q -t "$image" -f "test/Dockerfile.$distro" test >/dev/null
mkdir -p test/out && chmod 777 test/out
docker run --rm -v "$PWD/test/out:/out" "$image" sh -c 'rm -f /out/*' # files from the last run are owned by the container user
# The native decoration, built once per distro (incremental after that) into test/build-<distro>; the session installs it from there.
mkdir -p "test/build-$distro" && chmod 777 "test/build-$distro"
docker run --rm -v "$PWD:/src:ro" -v "$PWD/test/build-$distro:/build" "$image" sh -c 'cmake -S /src/look/decoration -B /build -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /build >/dev/null' \
  || echo "warning: the decoration did not build on $distro"
node="${DRI_NODE:-/dev/dri/renderD128}"
docker run --rm --name "etesian-plasma-$scenario" --device "$node" --group-add "$(stat -c %g "$node")" \
  -v "$PWD:/src:ro" -v "$PWD/test/out:/out" -v "$PWD/test/build-$distro:/deco:ro" -e ETESIAN_DECORATION_SO=/deco/org.etesian.decoration.so -e KWIN_GDB -e DEBUGINFOD_URLS "$image" timeout 180 /src/test/session.sh "$scenario"
cat test/out/result.txt
! grep -q ^FAIL test/out/result.txt
