#!/bin/sh
set -eu

cd "$(dirname "$0")"
base_url="http://127.0.0.1:${LAZYADMIN_HTTP_PORT:-80}"
probe_dir="$(mktemp -d)"
cleanup() {
    docker compose exec -T -u root web sh -c 'if test -f /tmp/lazyadmin-original-copy.sh; then cat /tmp/lazyadmin-original-copy.sh > /etc/copy.sh; chmod 0647 /etc/copy.sh; rm /tmp/lazyadmin-original-copy.sh; fi; rm -f /var/www/html/content/attachment/lazyadmin-probe.php /var/www/html/content/attachment/lazyadmin-probe.php5 /var/www/html/content/attachment/lazyadmin-probe.phtml /var/www/html/content/inc/ads/lazyadmin-probe.php' >/dev/null 2>&1 || true
    rm -rf "$probe_dir"
}
trap cleanup EXIT HUP INT TERM

curl -fsS "$base_url/" | grep -q 'Apache2 Ubuntu Default Page'
test "$(curl -fsS "$base_url/content/inc/lastest.txt")" = 1.5.1
curl -fsS "$base_url/content/inc/mysql_backup/" | grep -q 'mysql_bakup_20191129023059-1.5.1.sql'
curl -fsS "$base_url/content/inc/mysql_backup/mysql_bakup_20191129023059-1.5.1.sql" | grep -q 42f749ade7f9e195bf475f37a44cafcb

curl -fsS -c "$probe_dir/cookies" -b "$probe_dir/cookies" \
    --data-urlencode user=manager --data-urlencode passwd=Password123 \
    "$base_url/content/as/?type=signin" | grep -q 'Login success'

printf '%s\n' '<?php echo "lazyadmin-upload-ok"; ?>' > "$probe_dir/lazyadmin-probe.php5"
curl -fsS -c "$probe_dir/cookies" -b "$probe_dir/cookies" \
    -e "$base_url/content/as/?type=media_center" \
    -F 'upload[]=@'"$probe_dir/lazyadmin-probe.php5" \
    -F 'dir_name=' \
    "$base_url/content/as/?type=media_center&mode=upload" >/dev/null
test "$(curl -fsS "$base_url/content/attachment/lazyadmin-probe.php5")" = lazyadmin-upload-ok

printf '%s\n' '<?php echo "lazyadmin-upload-ok"; ?>' > "$probe_dir/lazyadmin-probe.phtml"
curl -fsS -c "$probe_dir/cookies" -b "$probe_dir/cookies" \
    -e "$base_url/content/as/?type=media_center" \
    -F 'upload[]=@'"$probe_dir/lazyadmin-probe.phtml" \
    -F 'dir_name=' \
    "$base_url/content/as/?type=media_center&mode=upload" >/dev/null
test "$(curl -fsS "$base_url/content/attachment/lazyadmin-probe.phtml")" = lazyadmin-upload-ok

printf '%s\n' '<?php echo "should-not-upload"; ?>' > "$probe_dir/lazyadmin-probe.php"
curl -fsS -c "$probe_dir/cookies" -b "$probe_dir/cookies" \
    -e "$base_url/content/as/?type=media_center" \
    -F 'upload[]=@'"$probe_dir/lazyadmin-probe.php" \
    -F 'dir_name=' \
    "$base_url/content/as/?type=media_center&mode=upload" >/dev/null
docker compose exec -T web test ! -e /var/www/html/content/attachment/lazyadmin-probe.php

curl -fsS -c "$probe_dir/cookies" -b "$probe_dir/cookies" \
    --data-urlencode 'adk=lazyadmin-probe' \
    --data-urlencode 'adv=<?php echo "lazyadmin-ads-ok"; ?>' \
    "$base_url/content/as/?type=ad&mode=save" >/dev/null
test "$(curl -fsS "$base_url/content/inc/ads/lazyadmin-probe.php")" = lazyadmin-ads-ok

docker compose exec -T -u www-data web sh -c 'test -r /home/itguy/user.txt && test -w /etc/copy.sh && sudo -l' | grep -q '/usr/bin/perl /home/itguy/backup.pl'
docker compose exec -T -u root web sh -c 'cp /etc/copy.sh /tmp/lazyadmin-original-copy.sh'
docker compose exec -T -u www-data web sh -c 'printf "id\n" > /etc/copy.sh; sudo /usr/bin/perl /home/itguy/backup.pl' | grep -q 'uid=0(root)'

printf '%s\n' 'LazyAdmin lab verification passed.'
