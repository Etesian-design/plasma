# The Belle Mail widget over Thunderbird's mail, without KDE PIM: a profile with an IMAP inbox kept offline (mbox). Its source is
# the default, "auto", which picks Thunderbird when it has an account. The newest mails and unread count, a mail opening in
# Thunderbird (a stand-in thunderbird command, test/before, records how), and a new mail showing up by itself.
source /src/test/check.sh
tb=~/.thunderbird; prof=$tb/abcd1234.default-release
mkdir -p "$prof/ImapMail/imap.example.org"
printf '[Profile0]\nName=default-release\nIsRelative=1\nPath=abcd1234.default-release\nDefault=1\n\n[General]\nStartWithLastProfile=1\nVersion=2\n' >$tb/profiles.ini
printf 'user_pref("mail.server.server1.directory-rel", "[ProfD]ImapMail/imap.example.org");\nuser_pref("mail.server.server1.name", "anna@example.org");\n' >"$prof/prefs.js"
mail() { # mail <status> <from> <subject> <date> <id>
  printf 'From - %s\nX-Mozilla-Status: %s\nFrom: %s\nTo: anna@example.org\nSubject: %s\nDate: %s\nMessage-ID: <%s@example.org>\n\nHello.\n\n' \
    "$(date -d "$4" '+%a %b %d %H:%M:%S %Y')" "$1" "$2" "$3" "$(date -R -d "$4")" "$5" >>"$prof/ImapMail/imap.example.org/INBOX"
}
mail 0001 "Library <noreply@example.org>" "Your loan is due" "-3 days" 4
mail 0001 "Aino <aino@example.org>" "Lunch on Friday?" "-1 day" 3
mail 0000 "Travel desk <travel@example.org>" "Your booking is confirmed" "-1 hour" 2
mail 0000 "Mikko Lahti <mikko@example.org>" "=?UTF-8?Q?Photos_from_the_weekend_=E2=98=80?=" "-20 minutes" 1
mail 0009 "Spam <spam@example.org>" "Deleted already" "-5 minutes" 9
added="$(plasma_eval 'const d = desktops()[0]; d.addWidget("org.etesian.mail", 560, 80, 360, 270); print(d.widgets().map(w => w.type).filter(t => t === "org.etesian.mail").join(","))')"
expect "the mail widget is on the desktop" "$added" "org.etesian.mail"
keys "sleep 4" "shot mail-thunderbird-1"
state() { grep -o "Mail widget: .*" /out/plasma.log | tail -n 1; }
expect "it lists Thunderbird's inbox, newest first, with the unread count" "$(state)" "Mail widget: 4 mails, 2 unread, first Mikko Lahti, account "
keys "move 740 181" "click" "sleep 2"
expect_has "a click opens the mail in Thunderbird" "$(cat /out/thunderbird-calls.txt 2>/dev/null)" "mid:1@example.org"
mail 0000 "Mikko Lahti <mikko@example.org>" "One more photo" "now" 5
for i in $(seq 30); do state | grep -q "5 mails" && break; sleep 0.5; done
expect "a new mail shows up by itself" "$(state)" "Mail widget: 5 mails, 3 unread, first Mikko Lahti, account "
keys "sleep 1" "shot mail-thunderbird-2"
grep -iE "etesian" /out/plasma.log | grep -v "Created graphical object was not placed in the graphics scene" | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the mail widget" "$(grep -c . /out/plasma-qml.txt)" 0
# Search (Super+Space), without KDE PIM: a person from Thunderbird's address book and her mail, each under its kind.
python3 - "$prof/abook.sqlite" <<'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE properties (card TEXT, name TEXT, value TEXT)")
db.executemany("INSERT INTO properties VALUES (?,?,?)", [("1", "DisplayName", "Aino Virtanen"), ("1", "PrimaryEmail", "aino@example.org")])
db.commit()
PY
keys "down LEFTMETA" "tap SPACE" "up LEFTMETA" "sleep 1.5" "tap A" "tap I" "tap N" "tap O" "sleep 2" "shot search-thunderbird"
# Clicking the person writes to her in Thunderbird; clicking her mail opens it.
keys "move 520 240" "click" "sleep 2"
expect_has "the person opens a new mail to her in Thunderbird" "$(cat /out/thunderbird-calls.txt)" "-compose to='Aino Virtanen <aino@example.org>'"
keys "down LEFTMETA" "tap SPACE" "up LEFTMETA" "sleep 1.5" "tap A" "tap I" "tap N" "tap O" "sleep 2" "move 520 314" "click" "sleep 2"
expect_has "her mail, under Mail, opens in Thunderbird" "$(cat /out/thunderbird-calls.txt)" "mid:3@example.org"
# The reader itself, against made-up profiles (look/mail/test/thunderbird.cpp): headers, flags, accounts, search.
/deco/mail/etesian-mail-thunderbird-test >>/out/result.txt 2>/out/thunderbird-test.log || true
