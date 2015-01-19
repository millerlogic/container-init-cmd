#!/bin/sh

# Usage: set the docker ENTRYPOINT ["/sbin/init-cmd"], use docker CMD as you would normally.
# Caveat: docker USER must be root; if you want another user, you can use ENV CMD_USER=.

set -e

if [ "$$" != "1" ]; then
	echo "Error: init needs PID 1, has $$" >&2
	error 1
fi

CMD="$@"

echo "ENV CMD_USER=$CMD_USER"
echo "CMD $CMD"

SERVICE_FILE=/etc/init.d/init-cmd
echo '#!/bin/bash
### BEGIN INIT INFO
# Provides:          init-cmd
# Required-Start:    $syslog $remote_fs
# Required-Stop:     $syslog $remote_fs
# Default-Start:     2 3 5
# Default-Stop:      0 1 6
# Description:       container init-cmd
### END INIT INFO
exec >>/var/log/init-cmd.log 2>&1
if [ x"$1" == x"start" ]; then
	SH=/bin/sh
	if [ x"'"$CMD_USER"'" != "x" ]; then
		mkdir -p ~'"$CMD_USER"' || true # Make sure home exists so su works.
		chown '"$CMD_USER"' ~'"$CMD_USER"' || true
		# sudo is not always available.
		SH="su '"$CMD_USER"' -s $SH"
	fi
	(
		$SH -c "'"$CMD"'" &
		echo "$?" >/var/run/init-cmd.pid
		wait
		rm /var/run/init-cmd.pid;
		halt
	) &
elif [ x"$1" == x"stop" ]; then
	if [ -f /var/run/init-cmd.pid ]; then
		kill $(cat /var/run/init-cmd.pid)
	fi
fi
' > $SERVICE_FILE
chmod +x $SERVICE_FILE

#ln -s $SERVICE_FILE /etc/rc2.d/S02init-cmd || true
update-rc.d init-cmd defaults
update-rc.d init-cmd enable

echo "id:2:initdefault:
si::sysinit:/etc/init.d/rcS
l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6" >/etc/inittab

echo "init PID is $$"
echo $$ >/var/run/init.pid
exec /sbin/init
