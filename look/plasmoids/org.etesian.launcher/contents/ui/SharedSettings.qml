// Settings the Events sidebar and the Overview's Events column share (weather city, feeds), kept in ~/.config/etesianrc
// so both show the same thing. Read with kreadconfig6 when created, written with kwriteconfig6 on every change.
import QtQuick
import org.kde.plasma.plasma5support as P5Support

QtObject {
    id: set
    property string weatherCity: ""
    property real weatherLat: 0
    property real weatherLon: 0
    property var feeds: []
    property bool loaded: false

    readonly property var keys: ["weatherCity", "weatherLat", "weatherLon", "feeds"]
    function q(v) { return "'" + String(v).replace(/'/g, "'\\''") + "'" }
    function write(key, value) {
        exec.connectSource("kwriteconfig6 --file etesianrc --group Events --key " + key + " " + q(Array.isArray(value) ? value.join(",") : value) + " # " + Date.now())
    }
    function setCity(name, lat, lon) {
        weatherCity = name; weatherLat = lat; weatherLon = lon
        write("weatherCity", name); write("weatherLat", lat); write("weatherLon", lon)
    }
    function setFeeds(list) { feeds = list; write("feeds", list) }

    property P5Support.DataSource exec: P5Support.DataSource {
        engine: "executable"
        onNewData: (source, data) => {
            const m = source.match(/--key (\w+)( #.*)?$/)
            if (m && source.indexOf("kreadconfig6") === 0) {
                const v = (data.stdout || "").trim()
                if (m[1] === "feeds") { const f = v ? v.split(",") : []; if (f.join(",") !== set.feeds.join(",")) set.feeds = f }
                else if (m[1] === "weatherCity") set.weatherCity = v
                else set[m[1]] = parseFloat(v) || 0
                set.loaded = true
            }
            disconnectSource(source)
        }
    }
    /** reads the settings again (each view does when it is shown: the other one may have changed them) */
    function reload() { for (const k of keys) exec.connectSource("kreadconfig6 --file etesianrc --group Events --key " + k + " # " + Date.now()) }
    Component.onCompleted: reload()
}
