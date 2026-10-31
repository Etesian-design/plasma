// The weather beside the time (XEventsPanel .x-ev__wx): icon, temperature, city with the conditions under it.
// Open-Meteo (no account, no key); nothing is fetched until a city is set. `cfg` is SharedSettings.qml. Without one, "Set city" opens a field in place.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: wx
    property var cfg
    property real temp: NaN
    property int code: -1
    property bool editing: false
    implicitWidth: editing ? 220 : row.implicitWidth; implicitHeight: 48

    /** WMO weather code → [text, icon] */
    function describe(c) {
        if (c === 0) return ["Clear", "weather-clear"]
        if (c <= 2) return ["Partly cloudy", "weather-few-clouds"]
        if (c === 3) return ["Cloudy", "weather-overcast"]
        if (c <= 48) return ["Fog", "weather-fog"]
        if (c <= 57) return ["Drizzle", "weather-showers-scattered"]
        if (c <= 67) return ["Rain", "weather-showers"]
        if (c <= 77) return ["Snow", "weather-snow"]
        if (c <= 82) return ["Showers", "weather-showers"]
        if (c <= 86) return ["Snow showers", "weather-snow-scattered"]
        return ["Thunderstorm", "weather-storm"]
    }
    function get(url, done) {
        const x = new XMLHttpRequest()
        x.onreadystatechange = () => { if (x.readyState === XMLHttpRequest.DONE && x.status === 200) { try { done(JSON.parse(x.responseText)) } catch (e) {} } }
        x.open("GET", url); x.send()
    }
    function refresh() {
        if (!cfg.weatherCity) return
        get("https://api.open-meteo.com/v1/forecast?latitude=" + cfg.weatherLat + "&longitude=" + cfg.weatherLon + "&current=temperature_2m,weather_code",
            j => { temp = j.current.temperature_2m; code = j.current.weather_code })
    }
    /** the place picker's matches (up to 10, as on the phone): name, "region, country", where it is */
    property var matches: []
    property string searched: ""
    function search(name) {
        const q = name.trim(); if (q.length < 2) { matches = []; searched = ""; return }
        get(cfg.geocoder + "/v1/search?count=10&name=" + encodeURIComponent(q), j => {
            if (field.text.trim() !== q) return // typed on since
            searched = q
            matches = (j.results || []).map(r => ({ name: r.name, detail: [r.admin1, r.country].filter(x => x).join(", "), lat: r.latitude, lon: r.longitude }))
        })
    }
    function choose(m) { cfg.setCity(m.name, m.lat, m.lon); editing = false; matches = []; refresh() }
    Component.onCompleted: refresh()
    Connections { target: wx.cfg; function onWeatherLonChanged() { wx.refresh() } } // the shared settings load after start
    Timer { interval: 30 * 60 * 1000; running: !!wx.cfg.weatherCity; repeat: true; onTriggered: wx.refresh() }

    Row {
        id: row
        visible: !wx.editing
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Kirigami.Icon { visible: wx.code >= 0; width: 44; height: 36; source: wx.describe(wx.code)[1]; anchors.verticalCenter: parent.verticalCenter }
        Text { visible: !isNaN(wx.temp); text: Math.round(wx.temp) + "°"; color: "white"; font { pixelSize: 34; weight: Font.Light } anchors.verticalCenter: parent.verticalCenter }
        // the city with the conditions under it; a click (on the city, or on "Set city") changes it
        MouseArea {
            anchors.verticalCenter: parent.verticalCenter
            width: place.implicitWidth; height: place.implicitHeight
            onClicked: { wx.editing = true; field.text = wx.cfg.weatherCity; field.forceActiveFocus() }
            Column {
                id: place
                Text { text: wx.cfg.weatherCity || "Weather"; color: "white"; font { pixelSize: 14; bold: true } }
                Text {
                    text: wx.cfg.weatherCity ? (wx.code >= 0 ? wx.describe(wx.code)[0] : "…") : "Set city"
                    color: wx.cfg.weatherCity ? "#C8C8C8" : "#4591FF"; font.pixelSize: 12
                }
            }
        }
    }
    QQC2.TextField {
        id: field
        visible: wx.editing
        anchors.verticalCenter: parent.verticalCenter; width: 220
        placeholderText: "City for the weather"
        onTextChanged: typing.restart()
        onAccepted: if (wx.matches.length) wx.choose(wx.matches[0])
        Keys.onEscapePressed: { wx.editing = false; wx.matches = [] }
    }
    Timer { id: typing; interval: 400; onTriggered: wx.search(field.text) }
    // Belle Weather's place picker: the towns called that, with their region and country (two can share a name)
    Rectangle {
        visible: wx.editing && (wx.matches.length > 0 || wx.searched !== "")
        anchors { top: field.bottom; topMargin: 4; right: field.right }
        width: 280; height: picks.implicitHeight + 8; radius: 8; color: "#1B1B1B"; border.color: "#33FFFFFF"
        Column {
            id: picks
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4 }
            Text { visible: !wx.matches.length; text: "No places called “" + wx.searched + "”"; color: "#8C8C8C"; font.pixelSize: 13; leftPadding: 12; height: 36; verticalAlignment: Text.AlignVCenter }
            Repeater {
                model: wx.matches
                delegate: MouseArea {
                    width: picks.width; height: 44; hoverEnabled: true
                    onClicked: wx.choose(modelData)
                    Rectangle { anchors.fill: parent; color: parent.containsMouse ? "#334591FF" : "transparent" }
                    Column {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                        Text { text: modelData.name; color: "white"; font.pixelSize: 14 }
                        Text { text: modelData.detail; color: "#8C8C8C"; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
