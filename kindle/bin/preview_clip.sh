#!/bin/sh
#
# KlipShare - Pre-visualizacao do post antes de publicar
# Exibe o texto na tela e gera menu de confirmacao.
#

CLIP_NUM="$1"
CLIP_CACHE="/mnt/us/extensions/klipshare/cache/clips.txt"
CLIPS_FILE="/mnt/us/documents/My Clippings.txt"
MENU_FILE="/mnt/us/extensions/klipshare/menu.json"
MAX_QUOTE_LEN=300

## Feedback visual
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

## JSON escape (multibyte-safe: tr trata newlines antes do sed)
je() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/ /g; s/\r//g' | tr '\n' ' '
}

## Recupera clipping do cache (regera se necessario)
if [ ! -f "${CLIP_CACHE}" ]; then
    awk '
    BEGIN { state="title"; book=""; text=""; n=0 }
    /^==========/ {
        if (text != "") {
            n++
            gsub(/\r/,"",book); gsub(/\r/,"",text)
            sub(/^\357\273\277/,"",book)
            gsub(/[\360-\367][\200-\277][\200-\277][\200-\277]/,"",book)
            gsub(/ \(z-library[^)]*\)/,"",book)
            gsub(/ \(1lib[^)]*\)/,"",book)
            gsub(/ \(z-lib[^)]*\)/,"",book)
            while (book ~ / \([^)]*\).*\([^)]*\)/) sub(/ \([^)]*\)$/, "", book)
            gsub(/\[[^\]]*\]/,"",book)
            gsub(/[[:space:]]+/," ",book)
            sub(/^[[:space:]]+/,"",book)
            gsub(/[[:space:]]+$/,"",book)
            print n "\t" book "\t" text
        }
        book=""; text=""; state="title"; next
    }
    state=="title" && NF>0  { book=$0; state="meta"; next }
    state=="meta"  && /^- / { state="blank"; next }
    state=="blank"           { state="text"; next }
    state=="text"  && NF>0  { text=(text=="")?$0:text" "$0 }
    ' "${CLIPS_FILE}" > "${CLIP_CACHE}" 2>/dev/null
fi

line=$(awk -F'\t' -v n="${CLIP_NUM}" '$1==n {print; exit}' "${CLIP_CACHE}")

if [ -z "${line}" ]; then
    feedback "ERRO: clipping #${CLIP_NUM} nao encontrado"
    exit 1
fi

book=$(printf '%s' "${line}" | cut -f2)
text=$(printf '%s' "${line}" | cut -f3)

## Capitaliza primeira letra (multibyte-safe via awk)
text=$(printf '%s' "${text}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

## Trunca (multibyte-safe via awk)
text_len=$(printf '%s' "${text}" | awk '{print length}')
if [ "${text_len}" -gt "${MAX_QUOTE_LEN}" ]; then
    text=$(printf '%s' "${text}" | awk -v n="${MAX_QUOTE_LEN}" '{printf substr($0,1,n)}')
    text="${text}..."
fi

## Exibe preview na tela via fbink
if [ "${FBINK_BIN}" != "true" ]; then
    short=$(printf '%s' "${text}" | awk -v n=55 '{printf substr($0,1,n)}')
    "${FBINK_BIN}" -q -m -y -12 "--- KlipShare: Pre-visualizacao ---" 2>/dev/null
    "${FBINK_BIN}" -q -m -y -10 "\"${short}...\"" 2>/dev/null
    "${FBINK_BIN}" -q -m -y -7  "-- ${book}" 2>/dev/null
    "${FBINK_BIN}" -q -m -y -5  "#kindle #leitura | KlipShare" 2>/dev/null
    "${FBINK_BIN}" -q -m -y -2  "Volte ao KUAL: Publicar ou Cancelar" 2>/dev/null
else
    feedback "Preview pronto. Volte ao KUAL: Publicar ou Cancelar."
fi

## Gera menu de confirmacao
label_pub=$(je "Publicar: \"$(printf '%s' "${text}" | awk -v n=38 '{printf substr($0,1,n)}')...\"")

{
    printf '{"items":[{"name":"KlipShare \xe2\x80\x94 Confirmar?","priority":0,"items":['
    printf '{"name":"%s","priority":1,"action":"./bin/share_threads.sh","params":"%s","exitmenu":false,"refresh":false,"status":false,"internal":"status Postando no Threads..."}' \
        "${label_pub}" "${CLIP_NUM}"
    printf ','
    printf '{"name":"Cancelar \xe2\x80\x94 Voltar a lista","priority":2,"action":"./bin/generate_menu.sh","params":"--quiet","exitmenu":false,"refresh":false,"status":false,"internal":"status Restaurando lista..."}'
    printf ']}]}'
} > "${MENU_FILE}"
