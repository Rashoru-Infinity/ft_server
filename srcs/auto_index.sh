#!/bin/bash

if [ ! -n "$AUTO_INDEX" ]; then
	export AUTO_INDEX="on"
fi
envsubst '${AUTO_INDEX}' < /etc/nginx/sites-available/default.template > /etc/nginx/sites-available/default
