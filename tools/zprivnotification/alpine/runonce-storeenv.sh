#!/bin/sh
printenv | sed -e 's/^\(.*\)$/export \1"/g' -e 's/=/="/' > /tmp/env.sh
