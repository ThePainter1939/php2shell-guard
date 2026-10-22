# 🛡️ php2shell-guard

A fast, zero-dependency Bash toolkit to **audit**, **scan logs**, **mitigate**, and **patch** Linux servers against the critical **[PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell)** remote code execution vulnerabilities (**CVE-2026-109618** and **CVE-2026-109619**).

## 🚨 What is PHP2Shell?

Disclosed on October 20–21, 2026, **PHP2Shell** refers to two critical vulnerabilities (CVSS v4.0 **9.2**) in the core PHP runtime affecting PHP versions **5.4 through 8.5** ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)):

* **CVE-2026-109618 (Out-of-Memory Corruption RCE):** If PHP runs out of memory while initializing request data (such as `$_POST` hash table buckets), its shutdown cleanup routine treats uninitialized memory as valid pointers, allowing unauthenticated attackers to execute arbitrary shell commands before any application code runs ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
* **CVE-2026-109619 (Stale Global State Use-After-Free RCE):** Leftover worker state from fatal-error backtraces or file upload progress tracking crosses request boundaries, letting a subsequent request on the same worker trigger remote code execution or memory disclosure ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).

| PHP Branch | Vulnerable Versions | Fixed Upstream Version | Status |
| :--- | :--- | :--- | :--- |
| **PHP 8.5** | `< 8.5.12` | **8.5.12** | Official patch available ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)) |
| **PHP 8.4** | `< 8.4.27` | **8.4.27** | Official patch available ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)) |
| **PHP 8.3** | `< 8.3.36` | **8.3.36** | Official patch available ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)) |
| **PHP 8.2** | `< 8.2.35` | **8.2.35** | Official patch available ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)) |
| **PHP 7.4 – 8.1** | All releases | Source backports / Vendor LTS | Check vendor advisories or upgrade to 8.2+ ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)) |
| **PHP 5.4 – 7.3** | All releases | None (End-of-Life) | Isolate or upgrade immediately ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)) |

## ⚡ Quick Start (One-Liner)

Clone this repository and run the script on your Linux server:

```bash
git clone https://github.com/ThePainter1939/php2shell-guard.git
cd php2shell-guard
chmod +x php2shell-guard.sh
sudo ./php2shell-guard.sh
```

Or run a specific mode directly from the command line:

```bash
# 1. Fast, read-only audit & log compromise check (safe to run anytime)
sudo ./php2shell-guard.sh --check

# 2. Upgrade PHP packages via apt/dnf/yum/apk & restart web workers (complete fix)
sudo ./php2shell-guard.sh --patch

# 3. Apply official temporary php.ini mitigations & restart workers (emergency stopgap)
sudo ./php2shell-guard.sh --mitigate
```

## 🔍 What `php2shell-guard.sh` Does

1. **Audits All PHP Binaries & Active Workers:** Scans CLI binaries, `php-fpm`, `php-cgi`, Apache (`mod_php`), FrankenPHP, and LiteSpeed processes so you aren't misled when the command-line PHP version differs from the running web runtime ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
2. **Checks Temporary `php.ini` Mitigations:** Verifies whether `memory_limit = -1`, `session.upload_progress.enabled = 0`, and `fatal_error_backtraces = 0` are active ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)).
3. **Scans Logs & Process Trees for Exploitation Signals:** Checks for active shell processes (`sh`, `bash`, `curl`, `wget`, `nc`) spawned under web server users (`www-data`, `apache`, `nginx`) and scans `/var/log/` for the signature pre-script initialization error (`Allowed memory size of ... bytes exhausted ... in Unknown on line 0`) and worker `Segmentation fault (11)` crashes dating back to October 17, 2026 ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
4. **Automates Patching & Worker Restarts:** Runs your distribution's package manager ([Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available), Debian, [AlmaLinux](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/), RHEL, Alpine) to install fixed PHP packages and automatically restarts running `php-fpm` and web server services so vulnerable workers are flushed from memory.

## ⚠️ Important Security Notes

* **Patching is the only complete fix:** Temporary `php.ini` mitigations and WAF rules ([Cloudflare](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/)) reduce exposure to known exploit vectors, but they do not completely eliminate the underlying memory safety flaws ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
* **Reverse-Proxy Request Limits:** If you use `--mitigate` (which sets `memory_limit = -1` so single requests don't fail mid-initialization), pair it with strict request body size limits on your reverse proxy (Nginx `client_max_body_size` or Apache `LimitRequestBody`) and container memory limits so attackers cannot exhaust host RAM ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).

## 📚 Official References & Advisories

* [PHP2Shell Overview — Wikipedia](https://en.wikipedia.org/wiki/PHP2Shell)
* [Tenable Research FAQ: CVE-2026-109618 & CVE-2026-109619](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)
* [Datadog Security Labs: Detection, Analysis, and Remediation](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)
* [watchTowr Labs Intelligence FAQ](https://watchtowr.com/intelligence/php-cve-2026-109618-faq/)
* [Ubuntu Security Notice: php2shell Fixes Available](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available)
* [AlmaLinux Security Blog: Patched PHP Packages](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/)
