#!/bin/sh
#
# KlipShare - Posta clipping no Threads
# Recebe o numero do clipping como argumento $1
#

CLIP_NUM="$1"
CLIP_CACHE="/mnt/us/extensions/klipshare/cache/clips.txt"
CLIPS_FILE="/mnt/us/documents/My Clippings.txt"
CREDS="/mnt/us/extensions/klipshare/config/credentials.conf"
QUEUE_DIR="/mnt/us/extensions/klipshare/cache/queue"
MAX_QUOTE_LEN=300

## --- Feedback visual na tela do Kindle ---
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

## --- Valida credenciais ---
if [ ! -f "${CREDS}" ]; then
    feedback "ERRO: credentials.conf nao encontrado"
    exit 1
fi

. "${CREDS}"

# Remove espaços acidentais nas extremidades
THREADS_USER_ID=$(printf '%s' "${THREADS_USER_ID}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
THREADS_ACCESS_TOKEN=$(printf '%s' "${THREADS_ACCESS_TOKEN}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "${THREADS_USER_ID}" ] || [ "${THREADS_USER_ID}" = "SEU_USER_ID_AQUI" ]; then
    feedback "ERRO: THREADS_USER_ID ausente em credentials.conf"
    exit 1
fi

# User ID deve ser numérico
case "${THREADS_USER_ID}" in
    *[!0-9]*|"") feedback "ERRO: THREADS_USER_ID invalido (deve ser numerico)"; exit 1 ;;
esac

if [ -z "${THREADS_ACCESS_TOKEN}" ] || [ "${THREADS_ACCESS_TOKEN}" = "SEU_ACCESS_TOKEN_AQUI" ]; then
    feedback "ERRO: THREADS_ACCESS_TOKEN ausente em credentials.conf"
    exit 1
fi

# Token deve começar com THAA
case "${THREADS_ACCESS_TOKEN}" in
    THAA*) ;;
    *) feedback "ERRO: THREADS_ACCESS_TOKEN invalido. Gere um novo em klipshare.vercel.app/setup"; exit 1 ;;
esac

## --- Localiza curl ---
CURL=""
for _c in /mnt/us/koreader/curl /usr/bin/curl /usr/local/bin/curl; do
    if [ -x "${_c}" ]; then
        CURL="${_c}"
        break
    fi
done
[ -z "${CURL}" ] && command -v curl >/dev/null 2>&1 && CURL="curl"

if [ -z "${CURL}" ]; then
    feedback "ERRO: curl nao encontrado. Instale o KOReader."
    exit 1
fi

## --- Recupera o clipping ---
if [ ! -f "${CLIP_CACHE}" ]; then
    awk '
    BEGIN { state="title"; book=""; text=""; n=0 }
    /^==========/ {
        if (text != "") {
            n++
            gsub(/\r/,"",book); gsub(/\r/,"",text)
            gsub(/[\360-\367][\200-\277][\200-\277][\200-\277]/,"",book)
            gsub(/ \(z-library[^)]*\)/,"",book)
            gsub(/ \(1lib[^)]*\)/,"",book)
            gsub(/ \(z-lib[^)]*\)/,"",book)
            sub(/ \([^)]*\) \(.*$/,"",book)
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

# Capitaliza primeira letra (ASCII e acentuadas)
text=$(printf '%s' "${text}" | sed \
    -e 's/^a/A/' -e 's/^b/B/' -e 's/^c/C/' -e 's/^d/D/' -e 's/^e/E/' \
    -e 's/^f/F/' -e 's/^g/G/' -e 's/^h/H/' -e 's/^i/I/' -e 's/^j/J/' \
    -e 's/^k/K/' -e 's/^l/L/' -e 's/^m/M/' -e 's/^n/N/' -e 's/^o/O/' \
    -e 's/^p/P/' -e 's/^q/Q/' -e 's/^r/R/' -e 's/^s/S/' -e 's/^t/T/' \
    -e 's/^u/U/' -e 's/^v/V/' -e 's/^w/W/' -e 's/^x/X/' -e 's/^y/Y/' \
    -e 's/^z/Z/' \
    -e 's/^á/Á/' -e 's/^à/À/' -e 's/^â/Â/' -e 's/^ã/Ã/' \
    -e 's/^é/É/' -e 's/^è/È/' -e 's/^ê/Ê/' \
    -e 's/^í/Í/' -e 's/^ì/Ì/' -e 's/^î/Î/' \
    -e 's/^ó/Ó/' -e 's/^ò/Ò/' -e 's/^ô/Ô/' -e 's/^õ/Õ/' \
    -e 's/^ú/Ú/' -e 's/^ù/Ù/' -e 's/^û/Û/' \
    -e 's/^ç/Ç/')

# Trunca texto respeitando o limite total de 500 chars do Threads
# Overhead: aspas (2) + "\n\n— " (4) + "\n\n#kindle #leitura\nCompartilhado via KlipShare para Kindle" (61)
overhead=$((${#book} + 67))
dyn_max=$((500 - overhead))
[ "${dyn_max}" -gt "${MAX_QUOTE_LEN}" ] && dyn_max="${MAX_QUOTE_LEN}"
[ "${dyn_max}" -lt 50 ] && dyn_max=50
if [ "${#text}" -gt "${dyn_max}" ]; then
    text=$(printf '%s' "${text}" | cut -c1-"${dyn_max}")
    text="${text}..."
fi

## --- Monta o texto do post ---
post_text="\"${text}\"

— ${book}

#kindle #leitura
Compartilhado via KlipShare para Kindle"

## --- Funções de rede ---
wifi_ok() {
    "${CURL}" -s --max-time 8 --head "https://graph.threads.net/" >/dev/null 2>&1
}

post_to_threads() {
    _pt="$1"
    _r=$("${CURL}" -s --max-time 30 -X POST \
        "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads" \
        -H "Authorization: Bearer ${THREADS_ACCESS_TOKEN}" \
        --data-urlencode "media_type=TEXT" \
        --data-urlencode "text=${_pt}" 2>/dev/null)
    _cid=$(printf '%s' "${_r}" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')
    [ -z "${_cid}" ] && return 1
    sleep 1
    _pub=$("${CURL}" -s --max-time 30 -X POST \
        "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish" \
        -H "Authorization: Bearer ${THREADS_ACCESS_TOKEN}" \
        -d "creation_id=${_cid}" 2>/dev/null)
    printf '%s' "${_pub}" | grep -q '"id"'
}

flush_queue() {
    [ -d "${QUEUE_DIR}" ] || return
    _sent=0
    for _qf in "${QUEUE_DIR}"/*.txt; do
        [ -f "${_qf}" ] || continue
        _qt=$(cat "${_qf}")
        if post_to_threads "${_qt}"; then
            rm -f "${_qf}"
            _sent=$((_sent + 1))
        fi
    done
    [ "${_sent}" -gt 0 ] && feedback "${_sent} post(s) pendente(s) enviado(s)!"
}

## --- Auto-refresh do token ---
auto_refresh_token() {
    new_resp=$("${CURL}" -s --max-time 20 \
        "https://graph.threads.net/refresh_access_token?grant_type=th_refresh_token&access_token=${THREADS_ACCESS_TOKEN}" \
        2>/dev/null)
    new_token=$(printf '%s' "${new_resp}" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')
    if [ -n "${new_token}" ] && [ "${new_token}" != "${THREADS_ACCESS_TOKEN}" ]; then
        tmp="${CREDS}.tmp"
        grep -v "^THREADS_ACCESS_TOKEN=" "${CREDS}" > "${tmp}"
        printf 'THREADS_ACCESS_TOKEN="%s"\n' "${new_token}" >> "${tmp}"
        mv "${tmp}" "${CREDS}"
        THREADS_ACCESS_TOKEN="${new_token}"
    fi
}

## --- Verifica WiFi ---
if ! wifi_ok; then
    mkdir -p "${QUEUE_DIR}"
    ts="$(date +%s 2>/dev/null || echo 0)_$$"
    printf '%s' "${post_text}" > "${QUEUE_DIR}/${ts}.txt"
    feedback "Sem WiFi. Post salvo na fila offline."
    exit 0
fi

## --- Renova token, envia fila pendente e posta ---
auto_refresh_token
feedback "Criando post no Threads..."
flush_queue

if post_to_threads "${post_text}"; then
    feedback "Postado no Threads com sucesso!"
    /mnt/us/extensions/klipshare/bin/generate_menu.sh --quiet 2>/dev/null &
else
    feedback "FALHA ao publicar. Tente novamente."
    exit 1
fi
