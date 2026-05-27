#!/usr/bin/env bash
# Run Flutter web on fixed port 3000.
set -e
cd "$(dirname "$0")"
exec flutter run -d chrome --web-port=3000 --web-hostname=localhost "$@"
