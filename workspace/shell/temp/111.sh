#! /bin/bash

case "$1" in
start)
    echo "start"
    ;;
stop)
    echo "start"
    ;;
status)
    echo "start"
    ;;
*)
    echo $"Usage: $0 {start|stop|status|restart|force-reload}"
    ;;
esac
