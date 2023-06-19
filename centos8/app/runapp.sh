#!/bin/sh
export KRB5_TRACE=/dev/stdout
export KRB5_KTNAME=/home/san/web-svc.keytab
$HOME/venv/bin/python app.py
