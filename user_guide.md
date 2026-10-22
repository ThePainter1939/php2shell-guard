# 🛡️ PHP2Shell Guard — End-User Step-by-Step Guide

Welcome to **PHP2Shell Guard**! This guide is written for website owners, developers, and server administrators who want to quickly check if their Linux server is vulnerable to **[PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell)** (**CVE-2026-109618** and **CVE-2026-109619**), scan for past attack attempts, and apply either the permanent PHP update or official emergency workarounds.

## 📋 Before You Begin (Prerequisites)

To run `php2shell-guard.sh`, you need:
1. **A Linux server** running your website or PHP application (such as [Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available), Debian, [AlmaLinux](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/), Rocky Linux, RHEL, CentOS, Fedora, or Alpine Linux).
2. **SSH access** to your server.
3. **`sudo` (administrator) privileges** so the script can read protected web server logs in `/var/log/` and install updated PHP packages.

> **Using Shared Hosting (cPanel / Plesk without SSH)?**  
> Because [PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell) lives in the core PHP engine rather than inside your website's PHP files ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)), shared hosting users without `sudo`/root SSH access should open their hosting control panel (**MultiPHP Manager** or **PHP Selector**), switch to a patched release (**PHP 8.5.12**, **8.4.27**, **8.3.36**, or **8.2.35**) ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)), or ask their hosting provider to apply the update immediately.

## 🚀 Step 1: Log In to Your Server & Download the Tool

1. Open **Terminal** (macOS/Linux) or **PowerShell / PuTTY** (Windows) and connect to your server via SSH:
   ```bash
   ssh your-username@your-server-ip
   ```

2. Clone this repository, enter the folder, and make the script executable:
   ```bash
   git clone https://github.com/YOUR-USERNAME/php2shell-guard.git
   cd php2shell-guard
   chmod +x php2shell-guard.sh
   ```

3. Launch the interactive menu with `sudo`:
   ```bash
   sudo ./php2shell-guard.sh
   ```

## 🔍 Step 2: Run a Safe, Read-Only Security Audit (Option `1`)

Always start by running a read-only check so you know your server's exact status before changing anything.

* **From the interactive menu:** Type **`1`** and press **Enter**.
* **Or directly from the command line:**
  ```bash
  sudo ./php2shell-guard.sh --check
  ```

### How to Read Your Audit Results

The audit finishes in under 2 seconds and prints four sections:

| Audit Section | Status Badge | What It Means & What You Should Do |
| :--- | :--- | :--- |
| **`[1/4]` Installed PHP Binaries** | `[SAFE]` | Your PHP version is **8.5.12+**, **8.4.27+**, **8.3.36+**, or **8.2.35+** ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)). No version upgrade is required for that binary. |
| **`[1/4]` Installed PHP Binaries** | `[VULNERABLE]` / `[WARNING]` | Your PHP version is older than the fixed release (or is an end-of-life branch like PHP 5.x, 7.x, 8.0, or 8.1) ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)). Proceed to **Step 3** immediately. |
| **`[2/4]` Active Web Workers** | `[ACTIVE]` | Shows running `php-fpm`, `apache2`, `httpd`, `frankenphp`, or `lsphp` worker processes ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)). Even after upgrading PHP packages, old workers stay vulnerable in RAM until restarted. |
| **`[3/4]` Temporary `php.ini` Flags** | `[MITIGATED]` / `[EXPOSED]` | Shows whether the PHP team's temporary `php.ini` workarounds (`memory_limit=-1`, `session.upload_progress.enabled=0`, `fatal_error_backtraces=0`) are enabled ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)). |
| **`[4/4]` Log & Process Scan** | `[CLEAN]` | No active web-spawned shells or signature pre-script memory exhaustion crashes were detected in `/var/log/`. |
| **`[4/4]` Log & Process Scan** | `[ALERT]` / `[WARNING]` | Found either a shell (`sh`, `bash`, `curl`, `wget`, `nc`) running under your web user (`www-data`, `apache`, `nginx`) or the signature CVE-2026-109618 crash (`Allowed memory size of ... bytes exhausted ... in Unknown on line 0`) ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)). Proceed to **Step 5** to investigate. |

## 🛠️ Step 3: Patch Your Server Permanently (Option `2` — Recommended)

According to the PHP security team, [Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote), and [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/), **updating PHP to a patched release is the only complete fix** for CVE-2026-109618 and CVE-2026-109619.

* **From the interactive menu:** Run `sudo ./php2shell-guard.sh`, type **`2`**, and press **Enter**.
* **Or directly from the command line:**
  ```bash
  sudo ./php2shell-guard.sh --patch
  ```

### What Option `2` (`--patch`) Does Automatically
1. **Detects your Linux distribution's package manager:** Supports `apt-get` ([Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available)/Debian), `dnf` ([AlmaLinux](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/)/RHEL/Rocky/Fedora), `yum` (CentOS/RHEL), and `apk` (Alpine).
2. **Upgrades all installed PHP packages:** Installs the latest security updates for `php*` and `libapache2-mod-php*`.
3. **Restarts all web and PHP worker services:** Restarts `php-fpm`, `apache2`, `httpd`, `nginx`, `lsws`, and `frankenphp` so no old, unpatched worker process remains running in memory ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
4. **Re-runs the version check:** Confirms that your installed binaries now report a patched version (**8.5.12**, **8.4.27**, **8.3.36**, or **8.2.35**) ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)).

> **Note on Linux Distribution Backports:**  
> Some Linux distributions (such as Debian and [Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available)) backport security fixes into their existing package version numbers (for example, `8.3.6-0ubuntu0.24.04.6`) rather than bumping the upstream number to `8.3.36` ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)). To verify a vendor backport on Ubuntu/Debian, run:
> ```bash
> apt-cache changelog php-common | grep -E "CVE-2026-109618|CVE-2026-109619"
> ```

## ⏱️ Step 4: Apply Temporary Emergency Mitigations (Option `3` — If You Cannot Upgrade Yet)

If you are running a legacy application that cannot be upgraded immediately, you can apply the PHP security team's temporary `php.ini` mitigations while you prepare your upgrade.

* **From the interactive menu:** Run `sudo ./php2shell-guard.sh`, type **`3`**, and press **Enter**.
* **Or directly from the command line:**
  ```bash
  sudo ./php2shell-guard.sh --mitigate
  ```

### What Option `3` (`--mitigate`) Does Automatically
1. Locates your server's active PHP `conf.d` directories (`/etc/php/*/conf.d`, `/etc/php.d`, `/usr/local/etc/php/conf.d`).
2. Creates `/etc/php/.../conf.d/99-php2shell-mitigation.ini` with three official settings ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote), [Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)):
   * `memory_limit = -1` — Prevents per-request soft out-of-memory aborts during `$_POST` hash table initialization (CVE-2026-109618).
   * `session.upload_progress.enabled = 0` — Disables automatic pre-script upload tracking to block stale upload state reuse (CVE-2026-109619).
   * `fatal_error_backtraces = 0` — Disables fatal-error backtrace retention across requests on PHP 8.5 (CVE-2026-109619).
3. Restarts your PHP and web server workers so the configuration loads immediately.

### Crucial Extra Step When Using `--mitigate`
Because setting `memory_limit = -1` removes PHP's per-request memory cap, **you must cap incoming request body sizes at your reverse proxy or web server** so attackers cannot crash your server by sending gigantic requests ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)):

* **For Nginx (`/etc/nginx/nginx.conf` inside `http { ... }`):**
  ```nginx
  client_max_body_size 10M;
  ```
* **For Apache (`/etc/apache2/apache2.conf` or `/etc/httpd/conf/httpd.conf`):**
  ```apache
  LimitRequestBody 10485760
  ```
* **For Cloudflare Users:** Enable [Cloudflare](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/) proxy mode (orange cloud) on your DNS records so Cloudflare's stopgap WAF rules filter known exploit payloads before they reach your server ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)).

## 🚨 Step 5: What to Do If the Log Scanner Shows an `[ALERT]`

Because Amazon Threat Intelligence observed [PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell) exploitation attempts starting on **October 17, 2026**—four days before public disclosure ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote))—follow these steps if Step 2 reports `[ALERT]`:

1. **Isolate the server immediately:** Temporarily restrict public HTTP/HTTPS traffic at your firewall or cloud security group until you finish patching, as recommended by CERT-EU and the NSA ([PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell)).
2. **Inspect the flagged log lines:** Check the exact timestamps of any `Allowed memory size of ... exhausted ... in Unknown on line 0` errors in your PHP error log and match them against your Nginx/Apache access logs (`POST` requests with large bodies or `200`/`500` responses) ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
3. **Check for unauthorized files or persistence:**
   * Inspect `/tmp`, `/var/tmp`, and `/dev/shm` for unfamiliar scripts or binaries owned by `www-data`, `apache`, or `nginx`.
   * Check `crontab -u www-data -l` for unauthorized scheduled tasks.
   * Check your web root (e.g., `/var/www/html`) for newly created or modified `.php` files since October 17, 2026:
     ```bash
     find /var/www -type f -name "*.php" -newermt "2026-10-17"
     ```
4. **Rotate secrets and rebuild if compromised:** Because a successful exploit runs commands with your web server user's permissions ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)), rotate any database passwords, API keys, or `.env` secrets readable by the web server user, and restore from a clean pre-October 17 backup if you find evidence of a web shell or backdoor.
