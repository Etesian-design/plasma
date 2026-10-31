# The weather place picker (Belle Weather): the city in Events opens a field; typing lists every town of that name with
# its region and country, and picking one keeps that town's coordinates (two Oulus: Finland and Wisconsin).
source /src/test/check.sh
# Open-Meteo's geocoding answered from inside the container (no internet in tests)
mkdir -p /tmp/geo/v1 && cat > /tmp/geo/v1/search <<'JSON'
{"results":[{"name":"Oulu","latitude":65.01236,"longitude":25.46816,"admin1":"North Ostrobothnia","country":"Finland"},
{"name":"Oulu","latitude":46.33,"longitude":-91.41,"admin1":"Wisconsin","country":"United States"}]}
JSON
(cd /tmp/geo && python3 -m http.server 6198 --bind 127.0.0.1 >/out/geo-server.log 2>&1 &)
for i in $(seq 20); do python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:6198/')" 2>/dev/null && break; sleep 0.2; done
kwriteconfig6 --file etesianrc --group Events --key geocoder "http://127.0.0.1:6198"
keys "down LEFTMETA" "tap N" "up LEFTMETA" "sleep 2" "shot weather-place-0"
keys "move 1527 148" "click" "sleep 1" "tap O" "tap U" "tap L" "tap U" "sleep 2" "shot weather-place-1"
expect_has "typing looks the town up" "$(cat /out/geo-server.log)" "GET /v1/search?count=10&name=oulu"
# the second match: Oulu, Wisconsin
keys "move 1420 228" "click" "sleep 2" "shot weather-place-2"
expect "picking keeps that town" "$(cfg etesianrc Events weatherCity)" "Oulu"
expect "with its own coordinates (Wisconsin, not Finland)" "$(cfg etesianrc Events weatherLat)" "46.33"
grep -iE "etesian" /out/plasma.log | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the Etesian widgets" "$(grep -c . /out/plasma-qml.txt)" 0
