#!/bin/bash

# Argument should be a JSON object with network interface names and IP addresses
RAW_INPUT="$1"

# Debugging: Log the raw input to understand what the script receives
echo "Raw input: $RAW_INPUT"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed."
  exit 1
fi

# Check if argument is provided
if [ -z "$RAW_INPUT" ]; then
  echo "Error: No input provided."
  exit 1
fi

# File to write IP addresses
FILE_PATH="/home/rooty/ip_list.txt"

# Ensure the directory is writable
if [ ! -w "$(dirname "$FILE_PATH")" ]; then
  echo "Error: Cannot write to the specified directory."
  exit 1
fi

# Write the IPs to the file
# Extract the values (IP addresses) from the JSON object
if ! echo "$RAW_INPUT" | jq -r 'values[]' > "$FILE_PATH"; then
  echo "Error: Could not write IPs to $FILE_PATH."
  exit 1
fi

# Write "name:ip" pairs to the file
if ! echo "$RAW_INPUT" | jq -r 'to_entries | .[] | "\(.key):\(.value)"' > "$FILE_PATH"; then
  echo "Error: Could not write IPs to $FILE_PATH."
  exit 1
fi

# Confirmation message
echo "IP list written to $FILE_PATH"
