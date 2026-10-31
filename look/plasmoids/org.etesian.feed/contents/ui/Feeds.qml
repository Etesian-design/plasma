// RSS and Atom feeds for the Feeds section: the newest items of all feeds, newest first, with the first picture of each.
import QtQuick

QtObject {
    id: feeds
    property var urls: []
    /** the addresses as a list (a one-entry list set from a script can arrive as a plain string, or comma-joined) */
    readonly property var list: (Array.isArray(urls) ? urls : String(urls || "").split(",")).map(u => String(u).trim()).filter(u => /^https?:\/\//.test(u))
    property var items: []   // [{ title, source, link, date, image }]
    property var perFeed: ({})

    function text(s) {
        return (s || "").replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1").replace(/<[^>]+>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim()
    }
    function tag(block, name) { const m = block.match(new RegExp("<" + name + "(?:\\s[^>]*)?>([\\s\\S]*?)</" + name + ">", "i")); return m ? m[1] : "" }
    function image(block) {
        const m = block.match(/<(?:media:thumbnail|media:content|enclosure)[^>]*url="([^"]+\.(?:jpe?g|png|webp)[^"]*)"/i)
            || block.match(/<img[^>]*src="([^"]+)"/i) || block.match(/&lt;img[^&]*src=&quot;([^&]+)&quot;/i)
        return m ? m[1] : ""
    }
    function parse(xml) {
        const source = text(tag(xml.replace(/<(item|entry)[\s>][\s\S]*/i, ""), "title"))
        const blocks = xml.match(/<(item|entry)[\s>][\s\S]*?<\/(item|entry)>/gi) || []
        return blocks.slice(0, 10).map(b => {
            const link = (b.match(/<link[^>]*href="([^"]+)"/i) || [])[1] || text(tag(b, "link"))
            const when = new Date(text(tag(b, "pubDate") || tag(b, "updated") || tag(b, "published") || tag(b, "dc:date")))
            return { title: text(tag(b, "title")), source: source, link: link, date: isNaN(when) ? new Date(0) : when, image: image(b) }
        })
    }
    function merge() {
        let all = []
        for (const u of list) all = all.concat(perFeed[u] || [])
        items = all.sort((a, b) => b.date - a.date).slice(0, 12)
    }
    function refresh() {
        for (const u of list) {
            const x = new XMLHttpRequest()
            x.onreadystatechange = () => {
                if (x.readyState !== XMLHttpRequest.DONE || x.status !== 200) return
                const p = Object.assign({}, perFeed); p[u] = parse(x.responseText); perFeed = p; merge()
            }
            x.open("GET", u); x.send()
        }
        merge()
    }
    onListChanged: refresh()
    property Timer timer: Timer { interval: 20 * 60 * 1000; running: feeds.list.length > 0; repeat: true; onTriggered: feeds.refresh() }
}
