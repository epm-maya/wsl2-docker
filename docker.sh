#!/bin/sh
set -ex

if [ "$(id -u)" != 0 ]; then
	echo >&2 "error: must be root to invoke $0"
	exit 1
fi

: ${CERTDIR:=/var/lib/wsl2-docker/tls}

PIDFILE='/var/run/docker.pid'
pid() {
	if [ -s "$PIDFILE" ]; then
		local pid
		pid="$(cat "$PIDFILE")"
		if ps "$pid" > /dev/null 2>&1; then
			echo "$pid"
			return 0
		fi
	fi
	return 1
}

start() {
	if pid="$(pid)"; then
		echo >&2 "error: Docker daemon is already running ($pid)"
		exit 1
	fi

	if [ ! -f "${CERTDIR}/server/key.pem" ]; then
		EXTRA_ARGS="-H tcp://0.0.0.0:2375"
	else
		EXTRA_ARGS="-H tcp://0.0.0.0:2376 --tlsverify"
		EXTRA_ARGS="${EXTRA_ARGS} --tlscacert=${CERTDIR}/ca/cert.pem"
		EXTRA_ARGS="${EXTRA_ARGS} --tlskey=${CERTDIR}/server/key.pem"
		EXTRA_ARGS="${EXTRA_ARGS} --tlscert=${CERTDIR}/server/cert.pem"
	fi

	mkdir -p /var/lib/wsl2-docker/log

	echo "Starting dockerd"
	dockerd -H unix:// $EXTRA_ARGS --pidfile "$PIDFILE" >> /var/lib/wsl2-docker/log/docker.log 2>&1 &
}

stop() {
	if pid="$(pid)"; then
		echo "Stopping dockerd ($pid)"
		kill "$pid"

		i=30
		while pid > /dev/null; do
			sleep 1
			i=$(expr $i - 1)
			if [ "$i" -le 0 ]; then
				echo >&2 "error: failed to stop Docker daemon"
				exit 1
			fi
		done
	fi
}

restart() {
	stop
	start
}

reload() {
	if ! pid="$(pid)"; then
		echo >&2 "error: Docker daemon is not running"
		exit 1
	fi
	kill -s HUP "$pid"
}

status() {
	if pid > /dev/null; then
		echo "Docker daemon is running"
		exit 0
	else
		echo "Docker daemon is not running"
		exit 1
	fi
}

case "$1" in
	start|stop|restart|reload|status)
		"$1"
		;;

	*)
		echo "Usage $0 {start|stop|restart|reload|status}"
		exit 1
		;;
esac
