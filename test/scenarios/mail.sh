# The Belle Mail widget over KMail's mail (Akonadi, with a local maildir account): the newest mails, the unread count, a mail
# opening in KMail, a new mail showing up by itself, and the account choice in the widget's settings.
source /src/test/check.sh
mkdir -p ~/.config/akonadi && printf '[%%General]\nDriver=QSQLITE\n' >~/.config/akonadi/akonadiserverrc
mail() { # mail <file> <from> <subject> <date>
  printf 'From: %s\nTo: anna@example.org\nSubject: %s\nDate: %s\nMessage-ID: <%s@example.org>\n\nHello.\n' "$2" "$3" "$(date -R -d "$4")" "$(basename "$1")" >"$1"
}
box=~/Mail/inbox; mkdir -p ~/Mail/{cur,new,tmp} $box/{cur,new,tmp}
mail $box/new/1 "Mikko Lahti <mikko@example.org>" "Photos from the weekend" "-20 minutes"
mail $box/new/2 "Travel desk <travel@example.org>" "Your booking is confirmed" "-1 hour"
mail "$box/cur/3:2,S" "Aino <aino@example.org>" "Lunch on Friday?" "-1 day"
mail "$box/cur/4:2,S" "Library <noreply@example.org>" "Your loan is due" "-3 days"
akonadictl start >/out/akonadi.log 2>&1
for i in $(seq 60); do qdbus6 org.freedesktop.Akonadi.Control /AgentManager >/dev/null 2>&1 && break; sleep 0.5; done
res=$(qdbus6 org.freedesktop.Akonadi.Control /AgentManager org.freedesktop.Akonadi.AgentManager.createAgentInstance akonadi_maildir_resource)
for i in $(seq 60); do qdbus6 "org.freedesktop.Akonadi.Resource.$res" /Settings >/dev/null 2>&1 && break; sleep 0.5; done
qdbus6 "org.freedesktop.Akonadi.Resource.$res" /Settings org.kde.Akonadi.Maildir.Settings.setPath "$HOME/Mail" >/dev/null
qdbus6 "org.freedesktop.Akonadi.Resource.$res" /Settings org.kde.Akonadi.Maildir.Settings.save >/dev/null
qdbus6 org.freedesktop.Akonadi.Control /AgentManager org.freedesktop.Akonadi.AgentManager.setAgentInstanceName "$res" "anna@example.org"
qdbus6 org.freedesktop.Akonadi.Control /AgentManager org.freedesktop.Akonadi.AgentManager.agentInstanceSynchronize "$res"
sleep 4
expect "the maildir account is set up" "$(qdbus6 org.freedesktop.Akonadi.Control /AgentManager org.freedesktop.Akonadi.AgentManager.agentInstanceName "$res" 2>&1)" "anna@example.org"
added="$(plasma_eval 'const d = desktops()[0]; d.addWidget("org.etesian.mail", 560, 80, 360, 270); print(d.widgets().map(w => w.type).filter(t => t === "org.etesian.mail").join(","))')"
expect "the mail widget is on the desktop" "$added" "org.etesian.mail"
keys "sleep 4" "shot mail-1"
state() { grep -o "Mail widget: .*" /out/plasma.log | tail -n 1; }
expect "it lists the inbox, newest first, with the unread count" "$(state)" "Mail widget: 4 mails, 2 unread, first Mikko Lahti, account anna@example.org"
# A mail opens in KMail: a stand-in KMail on the bus records the call.
python3 -c "import dbus, time; b = dbus.SessionBus(); b.request_name('org.kde.kmail'); time.sleep(600)" &
sleep 1
dbus-monitor "interface='org.kde.kmail.kmail'" >/out/kmail-calls.txt 2>&1 &
sleep 1
keys "move 740 181" "click" "sleep 1"
expect_has "a click shows the mail in KMail" "$(cat /out/kmail-calls.txt)" "member=showMail"
# A new mail arrives by itself.
mail $box/new/5 "Mikko Lahti <mikko@example.org>" "One more photo" "now"
for i in $(seq 30); do state | grep -q "5 mails" && break; sleep 0.5; done
expect "a new mail shows up by itself" "$(state)" "Mail widget: 5 mails, 3 unread, first Mikko Lahti, account anna@example.org"
keys "sleep 1" "shot mail-2"
# The settings: the source and which account (every inbox, or one).
keys "move 900 131" "rclick" "sleep 1" "move 998 149" "click" "sleep 3" "shot mail-settings"
keys "move 825 329" "click" "sleep 1" "move 823 424" "click" "sleep 1" "shot mail-settings-account" "move 1012 828" "click" "sleep 2"
expect "the account picked in the settings is kept" "$(plasma_eval 'const w = desktops()[0].widgets().filter(w => w.type === "org.etesian.mail")[0]; w.currentConfigGroup = ["General"]; print(w.readConfig("account"))')" "$res"
# (Plasma's own settings window warns about every page it creates: not the widget's)
grep -iE "etesian" /out/plasma.log | grep -v "Created graphical object was not placed in the graphics scene" | head -n 20 >/out/plasma-qml.txt || true
expect "no QML errors from the mail widget" "$(grep -c . /out/plasma-qml.txt)" 0
