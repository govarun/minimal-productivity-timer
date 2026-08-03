#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
pkill -x Bell 2>/dev/null || true
for _ in {1..30}; do
    pgrep -x Bell >/dev/null || break
    sleep 0.1
done
"$project_dir/Scripts/build-app.sh"
open "$project_dir/dist/Bell.app"
