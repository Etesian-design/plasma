#!/bin/bash
# Runs a test scenario in a throwaway Plasma container: test/run.sh <scenario> [ubuntu]. Screenshots land in test/out/.
# Needs Docker and a GPU render node (/dev/dri/renderD128): without OpenGL, KWin cannot take screenshots.
set -e
trap 'echo "run.sh: failed at line $LINENO: $BASH_COMMAND" >&2' ERR
cd "$(dirname "$0")/.."
scenario="${1:?scenario name, see test/scenarios}"; distro="${2:-ubuntu}"
image="etesian-plasma-test:$distro"
docker build -q -t "$image" -f "test/Dockerfile.$distro" test >/dev/null || { echo "run.sh: the $distro image did not build" >&2; docker build -t "$image" -f "test/Dockerfile.$distro" test 2>&1 | tail -20; exit 1; }
mkdir -p test/out && chmod 777 test/out
docker run --rm -v "$PWD/test/out:/out" "$image" sh -c 'rm -f /out/*' # files from the last run are owned by the container user
# The native decoration, built once per distro (incremental after that) into test/build-<distro>; the session installs it from there.
mkdir -p "test/build-$distro" && chmod 777 "test/build-$distro"
docker run --rm -v "$PWD:/src:ro" -v "$PWD/test/build-$distro:/build" "$image" sh -c 'cmake -S /src/look/decoration -B /build -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /build >/dev/null' \
  || echo "warning: the decoration did not build on $distro"
docker run --rm -v "$PWD:/src:ro" -v "$PWD/test/build-$distro:/build" "$image" sh -c 'cmake -S /src/look/mail -B /build/mail -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /build/mail >/dev/null' \
  || echo "warning: the mail plugin did not build on $distro"
docker run --rm -v "$PWD:/src:ro" -v "$PWD/test/build-$distro:/build" "$image" sh -c 'cmake -S /src/look/style -B /build/style -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build /build/style >/dev/null' \
  || echo "warning: the widget style did not build on $distro"
node="${DRI_NODE:-/dev/dri/renderD128}"
docker run --rm --name "etesian-plasma-$scenario" --device "$node" --group-add "$(stat -c %g "$node")" \
  -v "$PWD:/src:ro" -v "$PWD/test/out:/out" -v "$PWD/test/build-$distro:/deco:ro" -e ETESIAN_DECORATION_SO=/deco/org.etesian.decoration.so -e ETESIAN_MAIL_DIR=/deco/mail/org/etesian/mail -e ETESIAN_STYLE_SO=/deco/style/etesian.so -e KWIN_GDB -e DEBUGINFOD_URLS -e TZ "$image" timeout 300 /src/test/session.sh "$scenario" || rc=$?
# a scenario that stopped early (an error, a crash, the timeout) must not pass on the checks it reached
case ${rc:-0} in 0) ;; 124) echo "FAIL the scenario ran past 300 s and was stopped" >>test/out/result.txt ;;
  *) echo "FAIL the scenario stopped early (exit ${rc}): see the output above" >>test/out/result.txt ;; esac
cat test/out/result.txt
! grep -q ^FAIL test/out/result.txt
