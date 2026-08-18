#!/bin/sh
#
# KlipShare - Remove um destaque da lista (lista de exclusao)
# Recebe o numero do clipping como argumento $1
#

CLIP_NUM="$1"
case "${CLIP_NUM}" in
    ''|*[!0-9]*) exit 1 ;;
esac
CLIP_CACHE="/mnt/us/extensions/klipshare/cache/clips.txt"
EXCLUDED="/mnt/us/extensions/klipshare/cache/excluded.txt"

FBINK_BIN="true"
for _dir in /mnt/us/koreader /mnt/us/libkh/bin /var/tmp; do
    if [ -x "${_dir}/fbink" ]; then
        FBINK_BIN="${_dir}/fbink"
        break
    fi
done

feedback() {
    usleep 150000 2>/dev/null || true
    if [ "${FBINK_BIN}" != "true" ]; then
        "${FBINK_BIN}" -qpm -y -5 "$1" 2>/dev/null
    else
        eips 0 0 "$1" 2>/dev/null || true
    fi
}

line=$(awk -F'\t' -v n="${CLIP_NUM}" '$1==n {print $2"\t"$3; exit}' "${CLIP_CACHE}")
if [ -z "${line}" ]; then
    feedback "ERRO: clipping nao encontrado"
    exit 1
fi

mkdir -p "$(dirname "${EXCLUDED}")"
printf '%s\n' "${line}" >> "${EXCLUDED}"
rm -f "${CLIP_CACHE}"
feedback "Destaque removido."
