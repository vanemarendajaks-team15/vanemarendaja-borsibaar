#!/bin/sh
set -e
java -jar /app/backend.jar &
cd /app/frontend && exec node server.js
