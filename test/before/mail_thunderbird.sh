# The stand-in Thunderbird (records its arguments), on Plasma's PATH from the start: the widget opens mails with it.
mkdir -p ~/bin && printf '#!/bin/sh\necho "$@" >>/out/thunderbird-calls.txt\n' >~/bin/thunderbird && chmod +x ~/bin/thunderbird
export PATH="$HOME/bin:$PATH"
