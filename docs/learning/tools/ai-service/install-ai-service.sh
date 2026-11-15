#!/usr/bin/env bash
# Install on the board; --destdir stages files on a development PC without activation.
set -euo pipefail

fail() {
    printf 'install-ai-service: %s\n' "$*" >&2
    exit 1
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
stage_root=
enable_now=false
while (( $# )); do
    case "$1" in
        --enable)
            enable_now=true
            shift
            ;;
        --destdir)
            (( $# >= 2 )) || fail '--destdir requires an absolute directory'
            [[ "$2" = /* ]] || fail '--destdir must be absolute'
            stage_root="$(realpath -m -- "$2")"
            [[ "$stage_root" != / ]] || fail '--destdir must not be /'
            shift 2
            ;;
        -h|--help)
            printf '%s\n' \
                'Usage on board: sudo bash install-ai-service.sh [--enable]' \
                'Default: validate, install files and reload systemd; do not start or enable.' \
                '--enable: also enable boot startup and start the service now.' \
                'Development PC: bash install-ai-service.sh --destdir /absolute/staging/path'
            exit 0
            ;;
        *) fail "unknown argument: $1" ;;
    esac
done

[[ -z "$stage_root" ]] || ! "$enable_now" || fail '--destdir cannot be combined with --enable'
for packaged_file in start-ai-server.sh ai-server.env.example lubancat-ai.service; do
    [[ -f "$script_dir/$packaged_file" ]] || fail "missing packaged file: $packaged_file"
done

config_target="$stage_root/etc/default/lubancat-ai"
config_source="$script_dir/ai-server.env.example"
if [[ -e "$config_target" || -L "$config_target" ]]; then
    [[ -f "$config_target" ]] || fail "existing config is not a regular file: $config_target"
    config_source=$config_target
fi

if [[ -z "$stage_root" ]]; then
    (( EUID == 0 )) || fail 'run this installer with sudo on the LubanCat board'
    [[ -d /run/systemd/system ]] || fail 'systemd is not running on this machine'
    id cat >/dev/null 2>&1 || fail 'the service requires the board user cat'
    command -v systemctl >/dev/null || fail 'systemctl is required'
    command -v runuser >/dev/null || fail 'runuser is required'
    # Check permissions as the actual service user before modifying installed files.
    runuser -u cat -- /bin/bash "$script_dir/start-ai-server.sh" --config "$config_source" --check
fi

install -d -m 0755 "$stage_root/usr/local/bin" "$stage_root/etc/default" "$stage_root/etc/systemd/system"
backup_suffix="$(date -u +%Y%m%dT%H%M%SZ).$$"
install_managed_file() {
    local source_file=$1 target_file=$2 mode=$3
    if [[ -e "$target_file" || -L "$target_file" ]]; then
        [[ -f "$target_file" ]] || fail "target is not a regular file: $target_file"
        if ! cmp -s -- "$source_file" "$target_file"; then
            cp -p -- "$target_file" "$target_file.bak.$backup_suffix"
            printf 'Backed up: %s.bak.%s\n' "$target_file" "$backup_suffix"
        fi
    fi
    install -m "$mode" -- "$source_file" "$target_file"
}

install_managed_file "$script_dir/start-ai-server.sh" "$stage_root/usr/local/bin/lubancat-ai-start" 0755
install_managed_file "$script_dir/lubancat-ai.service" "$stage_root/etc/systemd/system/lubancat-ai.service" 0644
if [[ ! -e "$config_target" && ! -L "$config_target" ]]; then
    install -m 0644 -- "$script_dir/ai-server.env.example" "$config_target"
else
    printf 'Kept existing config: %s\n' "$config_target"
fi

if [[ -n "$stage_root" ]]; then
    printf 'Staged files under %s; no services were changed.\n' "$stage_root"
    exit 0
fi

systemctl daemon-reload
if "$enable_now"; then
    systemctl enable --now lubancat-ai.service
else
    printf '%s\n' 'Installed. To enable and start: sudo systemctl enable --now lubancat-ai.service'
fi
printf '%s\n' \
    'Status: sudo systemctl status lubancat-ai.service --no-pager' \
    'Logs:   sudo journalctl -u lubancat-ai.service -n 50 --no-pager' \
    'Health: curl --fail http://127.0.0.1:8080/health'
