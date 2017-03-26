#!/usr/bin/env bash

used_total=0
available_total=0

for n in $(yarn node -list 2>/dev/null | grep -v Total | grep -v Node-Id | \
  cut -d ' ' -f 1); do
  mem="$(yarn node -status "$n" 2>/dev/null | grep 'Memory-' | \
    cut -d ' ' -f 3 | sed 's/MB//g' | xargs)"
  used=${mem%% *}
  available=${mem##* }
  used_total=$(( used_total + used ))
  available_total=$(( available_total + available ))
done

if [[ $available_total == 0 ]]; then
  echo 0
else
  bc <<< "scale=4;($used_total/$available_total)*100"
fi
