#!/bin/bash

DIR="tmp"
FILE="$DIR/learned.txt"
MESSAGE="Setup complete. Ready for review."

# Create directory (idempotent)
mkdir -p "$DIR" >/dev/null 2>&1 || exit 1

# Create file if missing
touch "$FILE" >/dev/null 2>&1 || exit 2

# Write message into file (idempotent overwrite)
echo "$MESSAGE" > "$FILE"

# Print message to terminal
echo "$MESSAGE"

exit 0

