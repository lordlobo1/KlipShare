#!/bin/sh
#
# KlipShare - Posta clipping no Threads (e opcionalmente no Twitter/X)
# Recebe o numero do clipping como argumento $1
#

CLIP_NUM="$1"
CLIP_CACHE="/mnt/us/extensions/klipshare/cache/clips.txt"
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

eval "$(tr -d '\r' < "${CREDS}")"

# Remove espaços acidentais nas extremidades
THREADS_USER_ID=$(printf '%s' "${THREADS_USER_ID}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
THREADS_ACCESS_TOKEN=$(printf '%s' "${THREADS_ACCESS_TOKEN}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
TWITTER_ACCESS_TOKEN=$(printf '%s' "${TWITTER_ACCESS_TOKEN:-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
TWITTER_REFRESH_TOKEN=$(printf '%s' "${TWITTER_REFRESH_TOKEN:-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
TWITTER_MAX_LEN="${TWITTER_MAX_LEN:-280}"

if [ -z "${THREADS_USER_ID}" ] || [ "${THREADS_USER_ID}" = "SEU_USER_ID_AQUI" ]; then
    feedback "ERRO: THREADS_USER_ID ausente em credentials.conf"
    exit 1
fi

case "${THREADS_USER_ID}" in
    *[!0-9]*|"") feedback "ERRO: THREADS_USER_ID invalido (deve ser numerico)"; exit 1 ;;
esac

if [ -z "${THREADS_ACCESS_TOKEN}" ] || [ "${THREADS_ACCESS_TOKEN}" = "SEU_ACCESS_TOKEN_AQUI" ]; then
    feedback "ERRO: THREADS_ACCESS_TOKEN ausente em credentials.conf"
    exit 1
fi

case "${THREADS_ACCESS_TOKEN}" in
    TH*) ;;
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
    feedback "ERRO: abra o menu KUAL primeiro para construir o cache."
    exit 1
fi

line=$(awk -F'\t' -v n="${CLIP_NUM}" '$1==n {print; exit}' "${CLIP_CACHE}")

if [ -z "${line}" ]; then
    feedback "ERRO: clipping #${CLIP_NUM} nao encontrado"
    exit 1
fi

book=$(printf '%s' "${line}" | cut -f2)
raw_text=$(printf '%s' "${line}" | cut -f3)

# Capitaliza primeira letra (multibyte-safe via awk)
raw_text=$(printf '%s' "${raw_text}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

book_len=$(printf '%s' "${book}" | awk '{print length}')

## --- Trunca para Threads (ate 500 bytes) ---
# Overhead: aspas(2) + "\n\n— "(4) + book + "\n\nvia KlipShare for #Kindle"(25) + 4 newlines
th_overhead=$((book_len + 35))
th_max=$((500 - th_overhead))
[ "${th_max}" -gt "${MAX_QUOTE_LEN}" ] && th_max="${MAX_QUOTE_LEN}"
[ "${th_max}" -lt 50 ] && th_max=50
text="${raw_text}"
text_len=$(printf '%s' "${text}" | awk '{print length}')
if [ "${text_len}" -gt "${th_max}" ]; then
    text=$(printf '%s' "${text}" | awk -v n="${th_max}" '{printf substr($0,1,n)}')
    text="${text}..."
fi

## --- Trunca para Twitter/X (ate TWITTER_MAX_LEN bytes, padrao 280) ---
# Overhead: aspas(2) + "\n\n— "(4) + book + "\n\nvia KlipShare for #Kindle"(25) + 4 newlines = 35
# Premium: defina TWITTER_MAX_LEN=4096 (ou outro valor) no credentials.conf
tw_overhead=$((book_len + 35))
tw_max=$((TWITTER_MAX_LEN - tw_overhead))
[ "${tw_max}" -lt 30 ] && tw_max=30
tw_text="${raw_text}"
tw_len=$(printf '%s' "${tw_text}" | awk '{print length}')
tw_truncated=false
if [ "${tw_len}" -gt "${tw_max}" ]; then
    tw_text=$(printf '%s' "${tw_text}" | awk -v n="${tw_max}" '{printf substr($0,1,n)}')
    tw_text="${tw_text}..."
    tw_truncated=true
fi

## --- Monta texto do post Threads ---
post_text="\"${text}\"

— ${book}

via KlipShare for #Kindle"

## --- Funcoes de rede ---
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
    _cid=$(printf '%s' "${_r}" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"id"[[:space:]]*:[[:space:]]*"//;s/"//')
    [ -z "${_cid}" ] && return 1
    sleep 1
    _pub=$("${CURL}" -s --max-time 30 -X POST \
        "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish" \
        -H "Authorization: Bearer ${THREADS_ACCESS_TOKEN}" \
        -d "creation_id=${_cid}" 2>/dev/null)
    printf '%s' "${_pub}" | grep -q '"id"'
}

post_to_twitter() {
    _tw_body=$(printf '"%s"\n\n— %s\n\nvia KlipShare for #Kindle' "${tw_text}" "${book}")
    _tw_json=$(printf '%s' "${_tw_body}" | awk '
        BEGIN { printf "{\"text\":\"" }
        { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); if (NR > 1) printf "\\n"; printf "%s", $0 }
        END { printf "\"}" }
    ')
    _r=$("${CURL}" -s --max-time 30 -X POST \
        "https://api.twitter.com/2/tweets" \
        -H "Authorization: Bearer ${TWITTER_ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${_tw_json}" 2>/dev/null)
    if printf '%s' "${_r}" | grep -q '"status":401'; then
        return 2
    fi
    printf '%s' "${_r}" | grep -q '"id"'
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

## --- Auto-refresh do token Threads ---
auto_refresh_token() {
    new_resp=$("${CURL}" -s --max-time 20 \
        "https://graph.threads.net/refresh_access_token?grant_type=th_refresh_token&access_token=${THREADS_ACCESS_TOKEN}" \
        2>/dev/null)
    new_token=$(printf '%s' "${new_resp}" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')
    if [ -n "${new_token}" ] && [ "${new_token}" != "${THREADS_ACCESS_TOKEN}" ]; then
        tmp="${CREDS}.tmp"
        if grep -v "^THREADS_ACCESS_TOKEN=" "${CREDS}" > "${tmp}" && \
           printf 'THREADS_ACCESS_TOKEN="%s"\n' "${new_token}" >> "${tmp}" && \
           mv "${tmp}" "${CREDS}"; then
            THREADS_ACCESS_TOKEN="${new_token}"
        else
            rm -f "${tmp}"
        fi
    fi
}

## --- Auto-refresh do token Twitter (tokens rotativos) ---
auto_refresh_twitter_token() {
    _rt_body=$(printf '%s' "${TWITTER_REFRESH_TOKEN}" | \
        awk '{gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "{\"token\":\"%s\"}", $0}')
    new_resp=$("${CURL}" -s --max-time 20 \
        -X POST -H "Content-Type: application/json" \
        -d "${_rt_body}" \
        "https://klipshare.vercel.app/api/refresh_twitter" \
        2>/dev/null)
    new_at=$(printf '%s' "${new_resp}" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')
    new_rt=$(printf '%s' "${new_resp}" | grep -o '"refresh_token":"[^"]*"' | sed 's/"refresh_token":"//;s/"//')
    if [ -n "${new_at}" ] && [ -n "${new_rt}" ]; then
        tmp="${CREDS}.tmp"
        if grep -v "^TWITTER_ACCESS_TOKEN=" "${CREDS}" | \
           grep -v "^TWITTER_REFRESH_TOKEN=" > "${tmp}" && \
           printf 'TWITTER_ACCESS_TOKEN="%s"\n' "${new_at}" >> "${tmp}" && \
           printf 'TWITTER_REFRESH_TOKEN="%s"\n' "${new_rt}" >> "${tmp}" && \
           mv "${tmp}" "${CREDS}"; then
            TWITTER_ACCESS_TOKEN="${new_at}"
            TWITTER_REFRESH_TOKEN="${new_rt}"
        else
            rm -f "${tmp}"
        fi
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

## --- Renova token Threads, posta ---
auto_refresh_token
feedback "Criando post..."

if post_to_threads "${post_text}"; then
    ## --- Posta no Twitter se configurado ---
    tw_suffix=""
    if [ -n "${TWITTER_ACCESS_TOKEN}" ] && [ -n "${TWITTER_REFRESH_TOKEN}" ]; then
        post_to_twitter
        tw_result=$?
        if [ "${tw_result}" -eq 2 ]; then
            auto_refresh_twitter_token
            post_to_twitter
            tw_result=$?
        fi
        if [ "${tw_result}" -eq 0 ]; then
            [ "${tw_truncated}" = "true" ] \
                && tw_suffix=" + Twitter (encurtado)" \
                || tw_suffix=" + Twitter"
        else
            tw_suffix=" (Twitter: falhou)"
        fi
    fi
    feedback "Postado no Threads${tw_suffix}!"
    flush_queue 2>/dev/null &
    /mnt/us/extensions/klipshare/bin/generate_menu.sh --quiet 2>/dev/null &
else
    feedback "FALHA ao publicar. Tente novamente."
    exit 1
fi
