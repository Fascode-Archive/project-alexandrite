#!/bin/bash

declare root=${root}

case "${root}" in
    live:/dev/*)
        {
        printf 'KERNEL=="%s", RUN+="/sbin/initqueue %s %s %s"\n' \
            "${root#live:/dev/}" "--settled --onetime --unique" \
            "/sbin/kiwi-live-root" "${root#live:}"
        printf 'SYMLINK=="%s", RUN+="/sbin/initqueue %s %s %s"\n' \
            "${root#live:/dev/}" "--settled --onetime --unique" \
            "/sbin/kiwi-live-root" "${root#live:}"
        } >> /etc/udev/rules.d/99-live-kiwi.rules
        wait_for_dev -n "${root#live:}"
        ;;
    live:aoe:/dev/*)
        {
        printf 'KERNEL=="%s", RUN+="/sbin/initqueue %s %s %s"\n' \
            "${root#live:aoe:/dev/}" "--settled --onetime --unique" \
            "/sbin/kiwi-live-root" "${root#live:aoe:}"
        } >> /etc/udev/rules.d/99-live-aoe-kiwi.rules
        wait_for_dev -n "${root#live:aoe:}"
        ;;
esac
