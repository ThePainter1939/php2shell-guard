#!/usr/bin/env bash
# ==============================================================================
# php2shell-guard.sh — Fast Audit, Log Scanner & Emergency Mitigation Tool
# Targets: CVE-2026-109618 (OOM Corruption RCE) & CVE-2026-109619 (Use-After-Free RCE)
# Fixed Upstream Versions: PHP 8.5.12, 8.4.27, 8.3.36, 8.2.35
# License: MIT
# ==============================================================================

set -uo pipefail

VERSION="1.0.0"

# Terminal colors (disabled automatically if output is not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

banner() {
    echo -e "${BOLD}${BLUE}======================================================================${RESET}"
    echo -e "${BOLD}  PHP2Shell Guard v${VERSION} — CVE-2026-109618 & CVE-2026-109619 Toolkit${RESET}"
    echo -e "${BOLD}${BLUE}======================================================================${RESET}"
}

usage() {
    banner
    cat <<EOF

Usage:
  sudo ./php2shell-guard.sh [OPTION]

Options:
  --check      Run a fast, read-only vulnerability & log compromise scan
  --mitigate   Apply official PHP temporary php.ini mitigations & restart workers
  --patch      Update PHP packages via OS package manager & restart workers
  --help       Show this help message

If run without arguments, an interactive beginner-friendly menu will start.
EOF
}

# Compare semantic version strings: returns 0 if $1 >= $2, 1 otherwise
version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Evaluate a single PHP version string (e.g., "8.4.26")
evaluate_php_version() {
    local ver="$1"
    local major_minor
    major_minor="$(echo "$ver" | cut -d. -f1,2)"

    case "$major_minor" in
        8.5)
            if version_ge "$ver" "8.5.12"; then
                echo "SAFE|Patched (${ver} >= 8.5.12)"
            else
                echo "VULN|Vulnerable (${ver} < 8.5.12 — upgrade to 8.5.12+)"
            fi
            ;;
        8.4)
            if version_ge "$ver" "8.4.27"; then
                echo "SAFE|Patched (${ver} >= 8.4.27)"
            else
                echo "VULN|Vulnerable (${ver} < 8.4.27 — upgrade to 8.4.27+)"
            fi
            ;;
        8.3)
            if version_ge "$ver" "8.3.36"; then
                echo "SAFE|Patched (${ver} >= 8.3.36)"
            else
                echo "VULN|Vulnerable (${ver} < 8.3.36 — upgrade to 8.3.36+)"
            fi
            ;;
        8.2)
            if version_ge "$ver" "8.2.35"; then
                echo "SAFE|Patched (${ver} >= 8.2.35)"
            else
                echo "VULN|Vulnerable (${ver} < 8.2.35 — upgrade to 8.2.35+)"
            fi
            ;;
        7.4|8.0|8.1)
            echo "EOL_BACKPORT|End-of-Life (${ver}) — only source backports or vendor LTS patches exist; upgrade to PHP 8.2.35+"
            ;;
        5.*|7.0|7.1|7.2|7.3)
            echo "EOL_VULN|End-of-Life & Vulnerable (${ver}) — no official upstream patch; isolate or upgrade immediately"
            ;;
        *)
            echo "UNKNOWN|Unrecognized PHP branch (${ver})"
            ;;
    esac
}

# 1. Check installed PHP binaries and running workers
check_php_installations() {
    echo -e "\n${BOLD}[1/4] Checking Installed PHP Binaries & Web Workers...${RESET}"
    local found_any=0
    local vuln_count=0

    # Find PHP CLI and FPM binaries in standard paths
    local bins=()
    while IFS= read -r bin; do
        [ -n "$bin" ] && bins+=("$bin")
    done < <(which -a php php-fpm php-cgi 2>/dev/null | sort -u; find /usr/bin /usr/local/bin /usr/sbin /opt -maxdepth 3 -name "php*" -type f -executable 2>/dev/null | grep -E '/php([0-9.]*|-fpm[0-9.]*|-cgi[0-9.]*)$' | sort -u)

    # Deduplicate list
    local unique_bins=()
    while IFS= read -r b; do
        [ -n "$b" ] && unique_bins+=("$b")
    done < <(printf "%s\n" "${bins[@]:-}" | sort -u)

    if [ "${#unique_bins[@]}" -eq 0 ]; then
        echo -e "  ${YELLOW}[INFO]${RESET} No local PHP binary found in standard paths."
    else
        for bin in "${unique_bins[@]}"; do
            local raw_ver
            raw_ver="$("$bin" -v 2>/dev/null | head -n1 | grep -oE 'PHP [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' || true)"
            if [ -z "$raw_ver" ]; then
                continue
            fi
            found_any=1
            local full_ver_line
            full_ver_line="$("$bin" -v 2>/dev/null | head -n1 || true)"
            local res status msg
            res="$(evaluate_php_version "$raw_ver")"
            status="${res%%|*}"
            msg="${res#*|}"

            case "$status" in
                SAFE)
                    echo -e "  ${GREEN}[SAFE]${RESET} $bin -> $msg"
                    ;;
                VULN|EOL_VULN)
                    echo -e "  ${RED}[VULNERABLE]${RESET} $bin -> $msg"
                    echo -e "               Raw build: ${full_ver_line}"
                    echo -e "               (Note: If using Debian/Ubuntu/RHEL vendor packages, verify vendor changelog for CVE-2026-109618 backports.)"
                    vuln_count=$((vuln_count + 1))
                    ;;
                EOL_BACKPORT)
                    echo -e "  ${YELLOW}[WARNING]${RESET} $bin -> $msg"
                    vuln_count=$((vuln_count + 1))
                    ;;
                *)
                    echo -e "  ${YELLOW}[INFO]${RESET} $bin -> $msg"
                    ;;
            esac
        done
    fi

    # Check running PHP-FPM / Apache / FrankenPHP / LiteSpeed worker processes
    echo -e "\n${BOLD}[2/4] Checking Active Web & PHP Worker Processes...${RESET}"
    local running_procs
    running_procs="$(ps -ef 2>/dev/null | grep -E 'php-fpm|apache2|httpd|frankenphp|lsphp' | grep -v grep || true)"
    if [ -z "$running_procs" ]; then
        echo -e "  ${GREEN}[OK]${RESET} No running PHP-FPM, Apache, FrankenPHP, or LiteSpeed workers detected."
    else
        echo -e "  ${YELLOW}[ACTIVE]${RESET} Active web/PHP worker processes found (ensure workers are restarted after patching!):"
        echo "$running_procs" | head -n 8 | sed 's/^/    /'
    fi

    return "$vuln_count"
}

# 2. Check active php.ini mitigation settings
check_mitigations() {
    echo -e "\n${BOLD}[3/4] Checking Temporary php.ini Mitigation Settings...${RESET}"
    echo -e "  (Official interim guidance while awaiting full binary patching)"

    if ! command -v php >/dev/null 2>&1; then
        echo -e "  ${YELLOW}[SKIP]${RESET} 'php' CLI not in PATH; skipping runtime configuration check."
        return 0
    fi

    local mem_limit upload_prog fatal_bt
    mem_limit="$(php -r 'echo ini_get("memory_limit");' 2>/dev/null || echo "unknown")"
    upload_prog="$(php -r 'echo ini_get("session.upload_progress.enabled");' 2>/dev/null || echo "unknown")"
    fatal_bt="$(php -r 'echo ini_get("fatal_error_backtraces");' 2>/dev/null || echo "unknown")"

    if [ "$mem_limit" = "-1" ]; then
        echo -e "  ${GREEN}[MITIGATED]${RESET} memory_limit = -1 (reduces CVE-2026-109618 OOM corruption trigger)"
    else
        echo -e "  ${YELLOW}[EXPOSED]${RESET}   memory_limit = ${mem_limit} (PHP advisory recommends memory_limit=-1 paired with reverse-proxy body limits)"
    fi

    if [ "$upload_prog" = "0" ] || [ -z "$upload_prog" ]; then
        echo -e "  ${GREEN}[MITIGATED]${RESET} session.upload_progress.enabled = 0 (blocks CVE-2026-109619 upload state reuse)"
    else
        echo -e "  ${YELLOW}[EXPOSED]${RESET}   session.upload_progress.enabled = ${upload_prog} (PHP advisory recommends setting to 0)"
    fi

    if [ "$fatal_bt" = "0" ] || [ -z "$fatal_bt" ]; then
        echo -e "  ${GREEN}[MITIGATED]${RESET} fatal_error_backtraces = 0 (blocks PHP 8.5 CVE-2026-109619 backtrace state retention)"
    else
        echo -e "  ${YELLOW}[EXPOSED]${RESET}   fatal_error_backtraces = ${fatal_bt} (PHP advisory recommends setting to 0 on PHP 8.5)"
    fi
}

# 3. Scan logs and process trees for signs of PHP2Shell exploitation (since Oct 17, 2026)
scan_logs_and_processes() {
    echo -e "\n${BOLD}[4/4] Scanning Logs & Process Trees for PHP2Shell Exploitation Signals...${RESET}"
    echo -e "  (Checking for pre-script OOM errors, worker segfaults, and unexpected shells)"

    local alerts=0

    # Check for web worker processes spawning shells (sh, bash, dash, nc, curl, wget)
    local suspicious_children
    suspicious_children="$(ps -eo ppid,pid,user,comm,args 2>/dev/null | awk '
        NR==1 { next }
        $3 ~ /^(www-data|apache|nginx|httpd|nobody)$/ && $4 ~ /^(sh|bash|dash|nc|ncat|curl|wget|python3?)$/ { print }
    ' || true)"

    if [ -n "$suspicious_children" ]; then
        echo -e "  ${RED}[ALERT]${RESET} Web user is currently running shell/network utilities:"
        echo "$suspicious_children" | sed 's/^/    /'
        alerts=$((alerts + 1))
    else
        echo -e "  ${GREEN}[CLEAN]${RESET} No suspicious shell processes currently running under web server users."
    fi

    # Scan /var/log for signature CVE-2026-109618 / CVE-2026-109619 indicators
    local log_files=()
    while IFS= read -r lf; do
        [ -n "$lf" ] && log_files+=("$lf")
    done < <(find /var/log -maxdepth 3 -type f \( -name "*php*.log*" -o -name "*error*.log*" -o -name "syslog*" -o -name "messages*" \) 2>/dev/null)

    if [ "${#log_files[@]}" -eq 0 ]; then
        echo -e "  ${YELLOW}[INFO]${RESET} No readable web/PHP error logs found in /var/log (run with sudo for full log visibility)."
    else
        # Pattern 1: Pre-script initialization OOM error ("Allowed memory size of ... exhausted ... in Unknown on line 0")
        local oom_hits
        oom_hits="$(grep -E -i "Allowed memory size of [0-9]+ bytes exhausted.*in Unknown on line 0" "${log_files[@]}" 2>/dev/null | tail -n 5 || true)"
        if [ -n "$oom_hits" ]; then
            echo -e "  ${RED}[ALERT]${RESET} Found pre-script initialization OOM errors ('in Unknown on line 0' — primary CVE-2026-109618 indicator):"
            echo "$oom_hits" | sed 's/^/    /'
            alerts=$((alerts + 1))
        else
            echo -e "  ${GREEN}[CLEAN]${RESET} No 'Unknown on line 0' initialization OOM errors found in scanned logs."
        fi

        # Pattern 2: Worker segmentation faults during ASLR address probing
        local segv_hits
        segv_hits="$(grep -E "AH00052: child pid .* exit signal Segmentation fault|SIGSEGV|exit signal 11" "${log_files[@]}" 2>/dev/null | tail -n 5 || true)"
        if [ -n "$segv_hits" ]; then
            echo -e "  ${YELLOW}[WARNING]${RESET} Found web/PHP worker segmentation faults (can indicate ASLR probing or memory corruption):"
            echo "$segv_hits" | sed 's/^/    /'
            alerts=$((alerts + 1))
        else
            echo -e "  ${GREEN}[CLEAN]${RESET} No worker segmentation fault spikes detected in scanned logs."
        fi
    fi

    return "$alerts"
}

restart_web_workers() {
    echo -e "\n${BOLD}[*] Restarting PHP & Web Server Workers...${RESET}"
    local restarted=0
    if command -v systemctl >/dev/null 2>&1; then
        while IFS= read -r svc; do
            if [ -n "$svc" ]; then
                echo -e "  -> Restarting ${svc}..."
                systemctl restart "$svc" && restarted=$((restarted + 1))
            fi
        done < <(systemctl list-units --type=service --state=running 2>/dev/null | awk '{print $1}' | grep -E '^(php.*fpm|apache2|httpd|nginx|lsws|frankenphp)\.service$' || true)
    fi

    if [ "$restarted" -eq 0 ]; then
        echo -e "  ${YELLOW}[NOTE]${RESET} Could not auto-detect active systemd PHP/web services. Please manually restart your PHP-FPM, Apache, or container workers."
    else
        echo -e "  ${GREEN}[DONE]${RESET} Restarted ${restarted} service(s)."
    fi
}

apply_mitigations() {
    banner
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        echo -e "${RED}[ERROR]${RESET} Please run with sudo to write php.ini mitigation files: sudo $0 --mitigate"
        exit 1
    fi

    echo -e "\n${BOLD}Applying Official Temporary PHP2Shell Mitigations...${RESET}"
    echo -e "${YELLOW}IMPORTANT:${RESET} Temporary mitigations reduce exposure to known attack paths, but updating"
    echo -e "to PHP 8.5.12, 8.4.27, 8.3.36, or 8.2.35 is the ONLY complete fix.\n"

    local conf_dirs=()
    while IFS= read -r d; do
        [ -n "$d" ] && conf_dirs+=("$d")
    done < <(find /etc/php /etc/php.d /usr/local/etc/php/conf.d -type d -name "conf.d" 2>/dev/null | sort -u)

    if [ -d "/etc/php.d" ]; then
        conf_dirs+=("/etc/php.d")
    fi

    if [ "${#conf_dirs[@]}" -eq 0 ]; then
        echo -e "${RED}[ERROR]${RESET} Could not find standard PHP conf.d directories under /etc/php or /usr/local/etc/php."
        echo -e "Add these lines manually to your active php.ini and restart your PHP workers:"
        echo -e "  memory_limit = -1"
        echo -e "  session.upload_progress.enabled = 0"
        echo -e "  fatal_error_backtraces = 0"
        exit 1
    fi

    for dir in "${conf_dirs[@]}"; do
        local target_file="${dir}/99-php2shell-mitigation.ini"
        cat << 'EOF' > "$target_file"
; =====================================================================
; Emergency Interim Mitigation for PHP2Shell (CVE-2026-109618 / 109619)
; Generated by php2shell-guard.sh
; Note: Upgrade PHP to 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35 for full fix!
; =====================================================================
memory_limit = -1
session.upload_progress.enabled = 0
fatal_error_backtraces = 0
EOF
        echo -e "  ${GREEN}[WRITTEN]${RESET} ${target_file}"
    done

    restart_web_workers
    echo -e "\n${GREEN}[SUCCESS]${RESET} Temporary mitigations applied. Pair this with reverse-proxy request body size limits!"
}

patch_php() {
    banner
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        echo -e "${RED}[ERROR]${RESET} Please run with sudo to upgrade PHP packages: sudo $0 --patch"
        exit 1
    fi

    echo -e "\n${BOLD}Upgrading PHP Packages via OS Package Manager...${RESET}"
    if command -v apt-get >/dev/null 2>&1; then
        echo -e "  -> Detected Debian/Ubuntu (apt-get). Refreshing repositories and upgrading PHP packages..."
        apt-get update -y
        apt-get install --only-upgrade -y 'php*' 'libapache2-mod-php*' || true
    elif command -v dnf >/dev/null 2>&1; then
        echo -e "  -> Detected RHEL/AlmaLinux/Rocky/Fedora (dnf). Upgrading PHP packages..."
        dnf upgrade --refresh -y 'php*'
    elif command -v yum >/dev/null 2>&1; then
        echo -e "  -> Detected CentOS/RHEL (yum). Upgrading PHP packages..."
        yum update -y 'php*'
    elif command -v apk >/dev/null 2>&1; then
        echo -e "  -> Detected Alpine Linux (apk). Upgrading PHP packages..."
        apk update && apk upgrade
    else
        echo -e "${RED}[ERROR]${RESET} No supported package manager (apt-get, dnf, yum, apk) found."
        exit 1
    fi

    restart_web_workers
    echo -e "\n${BOLD}Re-verifying installed PHP versions after upgrade:${RESET}"
    check_php_installations || true
}

run_full_check() {
    banner
    check_php_installations || true
    check_mitigations || true
    scan_logs_and_processes || true
    echo -e "\n${BOLD}${BLUE}======================================================================${RESET}"
    echo -e "Scan complete. Run ${BOLD}sudo $0 --patch${RESET} to update PHP packages or"
    echo -e "${BOLD}sudo $0 --mitigate${RESET} to apply temporary php.ini workarounds."
    echo -e "${BOLD}${BLUE}======================================================================${RESET}"
}

interactive_menu() {
    banner
    echo -e "\nChoose an action:"
    echo -e "  ${BOLD}1)${RESET} Run Fast Vulnerability & Log Scan (Read-Only, Safe)"
    echo -e "  ${BOLD}2)${RESET} Patch PHP via OS Package Manager & Restart Workers (Recommended Fix)"
    echo -e "  ${BOLD}3)${RESET} Apply Temporary php.ini Mitigations & Restart Workers (Stopgap)"
    echo -e "  ${BOLD}4)${RESET} Exit"
    echo ""
    read -r -p "Enter choice [1-4]: " choice
    case "$choice" in
        1) run_full_check ;;
        2) patch_php ;;
        3) apply_mitigations ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid choice.${RESET}"; exit 1 ;;
    esac
}

# Main CLI entrypoint
case "${1:-}" in
    --check|-c)
        run_full_check
        ;;
    --mitigate|-m)
        apply_mitigations
        ;;
    --patch|-p)
        patch_php
        ;;
    --help|-h)
        usage
        ;;
    "")
        interactive_menu
        ;;
    *)
        echo -e "${RED}Unknown option: $1${RESET}"
        usage
        exit 1
        ;;
esac