# Thunderbird with no screen (Xvfb), to check the Etesian theme add-on loads. Arch: Kubuntu ships Thunderbird as a snap.
FROM archlinux:latest
RUN pacman -Syu --noconfirm --needed thunderbird xorg-server-xvfb xorg-xwd imagemagick python noto-fonts ttf-opensans && pacman -Scc --noconfirm
# enable.cfg: the user's "enable" switch for the theme, run by Thunderbird's autoconfig (test image only)
COPY enable.cfg /usr/lib/thunderbird/etesian-test.cfg
RUN printf 'pref("general.config.filename", "etesian-test.cfg");\npref("general.config.obscure_value", 0);\npref("general.config.sandbox_enabled", false);\n' >/usr/lib/thunderbird/defaults/pref/etesian-test.js
RUN useradd -m u
USER u
WORKDIR /home/u
