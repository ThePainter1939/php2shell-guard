# 📘 Complete Step-by-Step Guide: Publishing & Using `php2shell-guard`

This beginner-friendly guide walks you through **everything from scratch**:
1. **Part 1 (For You):** How to download your files and publish your GitHub repository in 5 minutes.
2. **Part 2 (For Website Owners):** How your users will run `php2shell-guard.sh` on their servers to protect against **[PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell)** (**CVE-2026-109618** and **CVE-2026-109619**).
3. **Part 3 (Under the Hood):** How each section of `php2shell-guard.sh` works in plain English so you can maintain your project with confidence.

## Part 1: How to Publish Your Repository on GitHub (For You)

You don't need to install Git or use the command line on your computer to publish this project. You can do it entirely in your web browser:

### Step 1: Save the Files to Your Computer
1. Open the **`php2shell-guard.sh`** file and the **`README.md`** file from the side panel (Canvas) and save/download both to a folder on your computer (for example, a folder named `php2shell-guard` on your Desktop).
2. *(Optional)* Save this **`GUIDE.md`** file into the same folder if you want to include a detailed tutorial inside your repository as well.

### Step 2: Create a Free GitHub Account (If You Don't Have One)
1. Go to **github.com** and sign in (or click **Sign up** to create a free account).
2. Remember your **GitHub username**—you will put it into the `README.md` file in Step 5.

### Step 3: Create a New Repository
1. Click the **`+`** icon in the top-right corner of GitHub (next to your profile picture) and click **New repository**.
2. In the **Repository name** box, type:
   ```text
   php2shell-guard
   ```
3. In the **Description** box, paste:
   ```text
   Fast, zero-dependency Bash toolkit to audit, scan logs, mitigate, and patch Linux servers against PHP2Shell (CVE-2026-109618 & CVE-2026-109619).
   ```
4. Select **Public** so anyone on the internet can see and use your tool.
5. Leave **Add a README file** **unchecked** (because you already have a custom `README.md` ready to upload).
6. Click **Create repository** at the bottom of the page.

### Step 4: Upload Your Files
1. On the quick-setup page that appears, look for the blue link that says **uploading an existing file** and click it.
2. Drag and drop **`php2shell-guard.sh`**, **`README.md`**, and **`GUIDE.md`** from your computer into the upload box.
3. Wait a second for the progress bars to finish.
4. Scroll down to the **Commit changes** box. In the first text field, type:
   ```text
   Initial release of php2shell-guard v1.0.0
   ```
5. Click the green **Commit changes** button.

### Step 5: Replace `YOUR-USERNAME` in `README.md`
1. On your new repository page, click on **`README.md`** in the file list.
2. Click the **pencil icon** (**Edit this file**) in the top-right corner of the file view.
3. Find the line that says:
   ```bash
   git clone https://github.com/YOUR-USERNAME/php2shell-guard.git
   ```
4. Replace `YOUR-USERNAME` with your real GitHub username.
5. Click the green **Commit changes...** button in the top-right corner, then click **Commit changes** in the popup.

🎉 **Congratulations!** Your repository is now live and ready to share.

## Part 2: Step-by-Step Guide for Website & Server Owners (Your Users)

When someone visits your GitHub repository to protect their website against [PHP2Shell](https://en.wikipedia.org/wiki/PHP2Shell), here is the exact workflow they follow on their Linux server ([Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available), Debian, [AlmaLinux](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/), RHEL, Rocky Linux, or Alpine):

### Step 1: Connect to the Web Server via SSH
The website owner opens their terminal (macOS/Linux) or PowerShell/PuTTY (Windows) and logs into their Linux server:
```bash
ssh username@your-server-ip
```

### Step 2: Download and Launch `php2shell-guard`
They copy and paste the 4-line Quick Start from your `README.md`:
```bash
git clone https://github.com/YOUR-USERNAME/php2shell-guard.git
cd php2shell-guard
chmod +x php2shell-guard.sh
sudo ./php2shell-guard.sh
```
* What `chmod +x php2shell-guard.sh` does: Gives the script permission to run as an executable program.
* What `sudo ./php2shell-guard.sh` does: Starts the interactive menu with administrator (`root`) privileges so it can inspect all `/var/log/` error logs and update system packages.

### Step 3: Run Option `1` First — Fast Vulnerability & Log Scan (Read-Only)
When the menu appears, the user types **`1`** and presses **Enter** (or runs `sudo ./php2shell-guard.sh --check` directly). This mode never changes any files on the server and checks four things in under 2 seconds:

| Check Stage | What the User Sees | What It Means |
| :--- | :--- | :--- |
| **`[1/4]` PHP Binaries** | `[SAFE]` or `[VULNERABLE]` | Compares every installed PHP binary (`php`, `php-fpm`, `php-cgi`) against the patched versions: **8.5.12**, **8.4.27**, **8.3.36**, and **8.2.35** ([TuxCare](https://tuxcare.com/blog/php2shell-cve/)). |
| **`[2/4]` Active Workers** | `[OK]` or `[ACTIVE]` | Lists running `php-fpm`, `apache2`, `httpd`, `frankenphp`, or `lsphp` processes so admins remember to restart them after updating ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)). |
| **`[3/4]` Temporary Mitigations** | `[MITIGATED]` or `[EXPOSED]` | Checks if `memory_limit=-1`, `session.upload_progress.enabled=0`, and `fatal_error_backtraces=0` are active ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)). |
| **`[4/4]` Log & Process Scan** | `[CLEAN]`, `[WARNING]`, or `[ALERT]` | Checks for web-spawned shells (`sh`, `bash`, `curl`, `wget`, `nc`) and scans `/var/log/` for `Allowed memory size of ... exhausted ... in Unknown on line 0` and worker `Segmentation fault (11)` crashes ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)). |

### Step 4: Choose Either Permanent Patching (`2`) or Emergency Stopgap (`3`)
Depending on their situation, the user picks one of two actions:

* **Option `2` (`sudo ./php2shell-guard.sh --patch`) — Best & Complete Fix:**
  1. Automatically detects the server's package manager (`apt-get`, `dnf`, `yum`, or `apk`).
  2. Downloads and installs the latest patched PHP packages from the OS vendor ([Ubuntu](https://ubuntu.com/blog/php2shell-vulnerability-fixes-available), [AlmaLinux](https://almalinux.org/blog/2026-10-21-php2shell-cve-2026-109618-cve-2026-109619/), Debian, RHEL, or Alpine).
  3. Automatically restarts all running `php-fpm` and web server (`apache2`, `httpd`, `nginx`, `lsws`, `frankenphp`) services so no old, vulnerable PHP worker stays in RAM ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
  4. Runs the version check again to confirm the server is protected.

* **Option `3` (`sudo ./php2shell-guard.sh --mitigate`) — Emergency Stopgap (If They Cannot Upgrade Right Away):**
  1. Finds all active PHP configuration folders (`/etc/php/*/conf.d`, `/etc/php.d`, `/usr/local/etc/php/conf.d`).
  2. Writes a drop-in configuration file named `99-php2shell-mitigation.ini` containing the official PHP team workarounds (`memory_limit = -1`, `session.upload_progress.enabled = 0`, and `fatal_error_backtraces = 0`) ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)).
  3. Automatically restarts active PHP and web server workers so the new settings take effect immediately.

## Part 3: How the Script Works Under the Hood (Beginner's Code Breakdown)

If someone asks you how your script works on GitHub, here is what each block of **`php2shell-guard.sh`** does:

1. **Safety Header (`set -uo pipefail`):**
   * `set -u` stops the script from accidentally using an undefined variable name.
   * `set -o pipefail` makes sure that if any command inside a pipeline fails, the script notices right away.
2. **Version Comparison (`version_ge` & `evaluate_php_version`):**
   * Uses `sort -V` (built into standard Linux `coreutils`) to compare version numbers accurately (so `8.4.27` is properly recognized as newer than `8.4.9`).
   * Checks each major/minor branch (`8.5`, `8.4`, `8.3`, `8.2`) against the exact patched version published by the PHP team on October 21, 2026 ([Tenable](https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote)).
3. **Multi-Binary Discovery (`check_php_installations`):**
   * Many servers have more than one version of PHP installed (for example, `php8.1` for the command line and `php-fpm8.4` for Nginx). Instead of just running `php -v` once, the script searches `/usr/bin`, `/usr/local/bin`, `/usr/sbin`, and `/opt` for every executable `php`, `php-fpm`, and `php-cgi` binary ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
4. **Live Exploit Detection (`scan_logs_and_processes`):**
   * Uses `ps -eo ppid,pid,user,comm,args` to see if the web server account (`www-data`, `apache`, `nginx`) is running a command shell (`sh`, `bash`, `nc`, `curl`, `wget`)—which is the #1 sign of an active remote code execution attack ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
   * Uses `grep -E` across `/var/log/` to look for `Allowed memory size of .* bytes exhausted .* in Unknown on line 0`. Because CVE-2026-109618 triggers while PHP is parsing the incoming HTTP POST form before any `.php` file starts, PHP logs the crash at `Unknown on line 0` ([Datadog Security Labs](https://securitylabs.datadoghq.com/articles/php2shell-critical-vulnerabilities-in-php/)).
