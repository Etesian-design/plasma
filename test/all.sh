#!/bin/bash
# Every scenario on Plasma 6.6 (Kubuntu 26.04) and on the latest Plasma (Arch). Screenshots of each run are kept in test/keep/<distro>/.
cd "$(dirname "$0")/.."
failed=0
for distro in ubuntu arch; do
  for s in test/scenarios/*.sh; do
    name=$(basename "$s" .sh)
    if test/run.sh "$name" "$distro" >"/tmp/etesian-$distro-$name.log" 2>&1; then echo "ok   $distro $name"
    else echo "FAIL $distro $name"; grep ^FAIL test/out/result.txt; failed=1; fi
    mkdir -p "test/keep/$distro" && cp test/out/*.png "test/keep/$distro/" 2>/dev/null
  done
done
exit $failed
