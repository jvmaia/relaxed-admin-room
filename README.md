# LazyAdmin local lab

This is a local recreation of the public TryHackMe LazyAdmin machine. It runs the original GPL-2.0 SweetRice 1.5.1 code and the publicly preserved SQL backup, then restores the machine-specific files and permissions described in LazyAdmin writeups. The intended sequence and the original user and root flags are preserved.

Run from this directory:

```sh
docker compose up --build -d
```

Open <http://127.0.0.1/> and treat that address as the target in a LazyAdmin writeup. HTTP and SSH use their original ports, `80` and `22`. The MariaDB service is reachable only inside the Compose network. If either port is occupied, set `LAZYADMIN_HTTP_PORT` or `LAZYADMIN_SSH_PORT` before running Compose; use the chosen HTTP port in your target URL. The default bind address is loopback; set `LAZYADMIN_BIND_ADDRESS=0.0.0.0` when using a separate attacker VM on a trusted private network.

If a writeup uses a reverse shell, put your host's reachable address in its callback. For a listener on the same computer as Docker, `host.docker.internal` generally works; `127.0.0.1` inside the target refers to the container itself. For a separate VM, use that VM's IP and ensure it is reachable from the container. Writeups that use the Ads feature or a `.php5`/`.phtml` media upload both follow the original CMS behavior.

To check the lab without following a walkthrough, run `./verify.sh`. It checks the exposed backup, CMS login, both PHP execution paths, and the configured sudo escalation, then removes its probe files. To reset the target fully, run `docker compose down -v` followed by `docker compose up --build -d`. This clears the database volume and restores the initial state.

This lab is intentionally vulnerable. Keep it on a private machine or network.

## Provenance

- SweetRice source: [sweetrice/SweetRice at commit `44bcb023`](https://github.com/sweetrice/SweetRice/tree/44bcb023b0647e5b3a7ada0127cd58b50e58c537), archived in [`vendor/sweetrice-1.5.1.tar.gz`](vendor/sweetrice-1.5.1.tar.gz). SHA-256: `2776a93f5547ec3e14ddc3a2e5e65d17ecf8bcc2bd53184474c11d562dda7ef6`. Its `license.txt` is included in the archive and the built image (GPL-2.0).
- The build replaces SweetRice's obsolete `get_magic_quotes_gpc()` check with `false` because PHP 7.4 no longer has magic quotes and reports that call as deprecated. This keeps the original CMS behavior on the chosen PHP runtime.
- SQL backup: [public LazyAdmin writeup artifact](https://github.com/r0bsec/thm-writeups/blob/main/lazyadmin/mysql_bakup_20191129023059-1.5.1.sql), reproduced at the same web path; the source repository's MIT license is included as [`vendor/backup-source-LICENSE`](vendor/backup-source-LICENSE).
- Behavior and machine details were cross-checked against [Rawsec's walkthrough](https://blog.raw.pm/en/TryHackMe-LazyAdmin-write-up/) and the [SweetRice Ads exploit record](https://www.exploit-db.com/exploits/40700). The original VM ran older Ubuntu/Apache/OpenSSH versions; this Docker build matches the challenge paths and exploitation chain rather than those exact service banners.
