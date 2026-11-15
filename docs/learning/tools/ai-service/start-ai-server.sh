#!/usr/bin/env bash
# Run as cat on the board. systemd supplies /etc/default/lubancat-ai.
set -euo pipefail

fail() {
    printf 'lubancat-ai: %s\n' "$*" >&2
    exit 1
}

config_file=
check_only=false
while (( $# )); do
    case "$1" in
        --config)
            (( $# >= 2 )) || fail '--config requires a file'
            config_file=$2
            shift 2
            ;;
        --check)
            check_only=true
            shift
            ;;
        -h|--help)
            printf '%s\n' \
                'Usage: start-ai-server.sh [--config FILE] [--check]' \
                'The config is a trusted local shell file containing KEY=value assignments.' \
                '--check validates paths and parameters without starting inference.'
            exit 0
            ;;
        *) fail "unknown argument: $1" ;;
    esac
done

if [[ -n "$config_file" ]]; then
    [[ -f "$config_file" && -r "$config_file" ]] || fail "cannot read config: $config_file"
    # Source only a local file controlled by the administrator.
    set -a
    # shellcheck disable=SC1090
    source "$config_file"
    set +a
fi

LLAMA_DIR="${LLAMA_DIR:-${HOME:?HOME is required}/workspace/ai/llama.cpp}"
MODEL_PATH="${MODEL_PATH:-$LLAMA_DIR/models/qwen2.5-0.5b-instruct-q4_k_m.gguf}"
AI_HOST="${AI_HOST:-0.0.0.0}"
AI_PORT="${AI_PORT:-8080}"
AI_THREADS="${AI_THREADS:-4}"
AI_CONTEXT="${AI_CONTEXT:-4096}"
AI_PREDICT="${AI_PREDICT:-1024}"
AI_PARALLEL="${AI_PARALLEL:-1}"
server="$LLAMA_DIR/build/bin/llama-server"

[[ "$LLAMA_DIR" = /* && -d "$LLAMA_DIR" ]] || fail "LLAMA_DIR must be an existing absolute directory: $LLAMA_DIR"
[[ "$MODEL_PATH" = /* ]] || fail 'MODEL_PATH must be absolute'
[[ -x "$server" ]] || fail "server is missing or not executable: $server"
[[ -f "$MODEL_PATH" && -r "$MODEL_PATH" && -s "$MODEL_PATH" ]] || fail "model is missing, unreadable or empty: $MODEL_PATH"
[[ "$AI_PORT" =~ ^[1-9][0-9]{0,4}$ ]] || fail 'AI_PORT must be an integer from 1 to 65535'
(( AI_PORT <= 65535 )) || fail 'AI_PORT must be an integer from 1 to 65535'
for parameter in AI_THREADS AI_CONTEXT AI_PREDICT AI_PARALLEL; do
    [[ "${!parameter}" =~ ^[1-9][0-9]*$ ]] || fail "$parameter must be a positive integer"
done
[[ -n "$AI_HOST" ]] || fail 'AI_HOST must not be empty'

if "$check_only"; then
    printf 'Preflight OK: server=%s\nmodel=%s\nlisten=%s:%s threads=%s context=%s predict=%s parallel=%s\n' \
        "$server" "$MODEL_PATH" "$AI_HOST" "$AI_PORT" \
        "$AI_THREADS" "$AI_CONTEXT" "$AI_PREDICT" "$AI_PARALLEL"
    exit 0
fi

cd "$LLAMA_DIR"
# exec keeps the server as systemd's main process so stop/restart signals reach it.
exec "$server" \
    -m "$MODEL_PATH" \
    -t "$AI_THREADS" \
    -c "$AI_CONTEXT" \
    -n "$AI_PREDICT" \
    -np "$AI_PARALLEL" \
    --host "$AI_HOST" \
    --port "$AI_PORT"
