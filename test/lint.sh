#!/bin/bash
# Static checks that run without Docker. A grouped property followed by ";" (font { … }; x: 1) is a QML parse error that only
# shows up when Plasma loads the widget.
cd "$(dirname "$0")/.."
bad=$(grep -rnE "\b[a-z]+ \{[^{}]*\}; " --include=*.qml look behaviour)
[ -z "$bad" ] && echo "ok   lint" || { echo "FAIL lint: grouped property followed by ';'"; echo "$bad"; exit 1; }
# Files shared between widgets (a widget can only load files from its own package) must stay identical copies.
p=look/plasmoids
for f in EventsView.qml Weather.qml Feeds.qml SharedSettings.qml Agenda.qml Squircle.qml; do
  cmp -s "$p/org.etesian.events/contents/ui/$f" "$p/org.etesian.launcher/contents/ui/$f" || { echo "FAIL lint: $f differs between org.etesian.events and org.etesian.launcher"; exit 1; }
done
for f in Search.qml etesianicons.js Squircle.qml; do
  cmp -s "$p/org.etesian.launcher/contents/ui/$f" "$p/org.etesian.spotlight/contents/ui/$f" || { echo "FAIL lint: $f differs between org.etesian.launcher and org.etesian.spotlight"; exit 1; }
done
for f in Feeds.qml SharedSettings.qml; do
  cmp -s "$p/org.etesian.events/contents/ui/$f" "$p/org.etesian.feed/contents/ui/$f" || { echo "FAIL lint: $f differs between org.etesian.events and org.etesian.feed"; exit 1; }
done
echo "ok   shared copies"
# the squircle is the N9 superellipse n = 2.8 (every side curves); n = 4 (sqrt / ** 0.5) reads as a rounded square
bad=$(grep -rlE "sqrt\(Math\.abs\((c|s|co|si|cos|sin)\)\)|(qPow|Math\.pow)\(q?[Aa]bs\(\w+\), 0\.5\)|abs\(\w+\)\) \*\* 0\.5" look scripts --include=*.qml --include=*.cpp --include=*.ts --include=*.js || true)
[ -z "$bad" ] && echo "ok   squircle n = 2.8" || { echo "FAIL squircle drawn with n = 4 in: $bad"; exit 1; }
# Events draws one line above each section: the SectionHeader's. A full-width divider Rectangle elsewhere doubled it under the
# time and the month (reported twice).
n=$(grep -c "color: panel.divider" "$p/org.etesian.events/contents/ui/EventsView.qml")
[ "$n" = 1 ] && echo "ok   Events one rule per section" || { echo "FAIL Events: $n divider lines, want only the SectionHeader's"; exit 1; }
