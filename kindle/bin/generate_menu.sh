#!/bin/sh
#
# KlipShare - Gera menu.json com os clippings do My Clippings.txt
# Chamado como acao pelo KUAL. Escreve o resultado em menu.json.
#

CLIPS_FILE="/mnt/us/documents/My Clippings.txt"
CLIP_CACHE="/mnt/us/extensions/klipshare/cache/clips.txt"
MENU_FILE="/mnt/us/extensions/klipshare/menu.json"
MAX_CLIPS=30
MAX_LABEL=55
QUIET=false
[ "$1" = "--quiet" ] && QUIET=true

## Feedback visual
FBINK_BIN="true"
for _dir in /mnt/us/koreader /mnt/us/libkh/bin /var/tmp; do
    if [ -x "${_dir}/fbink" ]; then
        FBINK_BIN="${_dir}/fbink"
        break
    fi
done

feedback() {
    [ "${QUIET}" = "true" ] && return
    usleep 150000 2>/dev/null || true
    if [ "${FBINK_BIN}" != "true" ]; then
        "${FBINK_BIN}" -qpm -y -5 "$1" 2>/dev/null
    else
        eips 0 0 "$1" 2>/dev/null || true
    fi
}

feedback "Lendo clippings..."

mkdir -p "$(dirname "${CLIP_CACHE}")"

## Parseia My Clippings.txt → cache TSV: num TAB livro TAB texto
awk '
BEGIN { state="title"; book=""; text=""; n=0 }
/^==========/ {
    if (text != "") {
        n++
        gsub(/\r/, "", book); gsub(/\r/, "", text)
        gsub(/[\360-\367][\200-\277][\200-\277][\200-\277]/, "", book)
        gsub(/ \(z-library[^)]*\)/, "", book)
        gsub(/ \(1lib[^)]*\)/, "", book)
        gsub(/ \(z-lib[^)]*\)/, "", book)
        sub(/ \([^)]*\) \(.*$/, "", book)
        gsub(/\[[^\]]*\]/, "", book)
        gsub(/[[:space:]]+/, " ", book)
        sub(/^[[:space:]]+/, "", book)
        gsub(/[[:space:]]+$/, "", book)
        print n "\t" book "\t" text
    }
    book=""; text=""; state="title"; next
}
state=="title" && NF>0 { book=$0; state="meta"; next }
state=="meta"  && /^- / { state="blank"; next }
state=="blank"           { state="text"; next }
state=="text"  && NF>0  { text=(text=="")?$0:text" "$0 }
' "${CLIPS_FILE}" 2>/dev/null | tail -n "${MAX_CLIPS}" > "${CLIP_CACHE}"

## Adiciona highlights do KOReader respeitando o limite total MAX_CLIPS
mc_count=$(awk 'END{print NR}' "${CLIP_CACHE}" 2>/dev/null || echo 0)
ko_limit=$((MAX_CLIPS - mc_count))

if [ "${ko_limit}" -gt 0 ]; then
    KO_TMP="/tmp/klipshare_ko.txt"
    : > "${KO_TMP}"
    find /mnt/us/documents -name "metadata.*.lua" -type f 2>/dev/null > /tmp/klipshare_ko_list.txt
    while IFS= read -r lua_file; do
        sdr_dir=$(dirname "${lua_file}")
        book=$(basename "${sdr_dir}" .sdr)
        book=$(printf '%s' "${book}" | sed 's/\[[^]]*\]//g;s/  */ /g;s/^ //;s/ $//')
        [ -z "${book}" ] && continue
        awk -v book="${book}" '
        BEGIN { hl=0; notes="" }
        /\["highlighted"\] *= *true/ { hl=1 }
        /\["notes"\] *= *"/ {
            notes=$0
            sub(/^.*\["notes"\] *= *"/, "", notes)
            sub(/"[[:space:]]*,?[[:space:]]*$/, "", notes)
        }
        /^[[:space:]]*\}/ {
            if (hl && length(notes)>5) print book "\t" notes
            hl=0; notes=""
        }
        ' "${lua_file}"
    done < /tmp/klipshare_ko_list.txt >> "${KO_TMP}"
    rm -f /tmp/klipshare_ko_list.txt

    if [ -s "${KO_TMP}" ]; then
        n="${mc_count}"
        awk -F'\t' -v start="${n}" -v limit="${ko_limit}" \
            'NR<=limit{print start+NR "\t" $1 "\t" $2}' "${KO_TMP}" >> "${CLIP_CACHE}"
    fi
    rm -f "${KO_TMP}"
fi

total=$(awk 'END{print NR}' "${CLIP_CACHE}" 2>/dev/null || echo 0)

## Constroi itens JSON — single awk pass (multibyte-safe, sem forks por clipping)
items=$(awk -F'\t' -v ml="${MAX_LABEL}" '
function jesc(s) {
    gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s)
    gsub(/\t/, " ", s);    gsub(/\r/, "", s)
    return s
}
{
    pl = length($3) + length($2) + 67
    lb = (length($3) > ml) ? substr($3,1,ml) "..." : $3
    if (NR > 1) printf ","
    printf "{\"name\":\"%s\",\"priority\":%s,\"action\":\"./bin/share_threads.sh\",\"params\":\"%s\",\"exitmenu\":false,\"refresh\":false,\"status\":false,\"internal\":\"status Postando no Threads...\"}",
        jesc("[" pl "] " lb), $1, $1
}
' "${CLIP_CACHE}")

## Adiciona item de atualizacao no fim
refresh_item='{"name":"Atualizar lista","priority":99,"action":"./bin/generate_menu.sh","exitmenu":false,"refresh":true,"status":false,"internal":"status Atualizando clippings..."}'
[ -n "${items}" ] && items="${items},${refresh_item}" || items="${refresh_item}"

## Escreve menu.json
printf '{"items":[{"name":"KlipShare \xe2\x80\x94 Threads (%s clippings)","priority":0,"items":[%s]}]}' \
    "${total}" "${items}" > "${MENU_FILE}"

feedback "Pronto! Volte ao KUAL e reabra o KlipShare."
