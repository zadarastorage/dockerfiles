#!/usr/bin/env bash

files=$(mount | grep xfs | cut -d' ' -f3 | awk '{f=$1"/fill"; print f}'| paste -sd ":" -)
fio /app/fio-fill.job --filename ${files}