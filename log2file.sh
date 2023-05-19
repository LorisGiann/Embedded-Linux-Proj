#!/bin/bash

# This simple script writes to log files the lines you pass to stdin
# The scripts rotate the files when they get over a certain size, so that older information gets deleted
# Usage:
#   log2file <filename> <max_size> <max_files>"
# <filename>: the destination file path (file and path are created if not already present)
# <max_size>: size in bytes over which the file is rotate (actually it may be a little over, since checks are done after a certain number of lines to reduce overhead)
# <max_files>: the number of files over which older ones are deleted

# Function to rotate the file and delete the oldest file if necessary
rotate_file() {
  local file=$1
  local max_size=$2
  local max_files=$3

  if [[ -f "$file" ]]; then
    local size=$(stat -c%s "$file")

    if [[ size -gt max_size ]]; then
      # Rotate the file
      echo "rotating file"
      for (( i=max_files-1; i>=1; i-- )); do
        local current_file="${file}.${i}"
        local next_file="${file}.$((i+1))"

        if [[ -f "$current_file" ]]; then
          mv "$current_file" "$next_file"
        fi
      done

      # Rotate the main file
      mv "$file" "${file}.1"
    fi
  fi
}

# Main script
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <filename> <max_size> <max_files>"
  exit 1
fi

filename=$1
max_size=$2
max_files=$3

# Create the initial file if it doesn't exist
mkdir -p "$(dirname "$filename")"

line_count=0

# Loop to read lines from stdin
while IFS= read -r line; do
  # Write the line to the file
  echo "$line" >> "$filename"

  ((line_count++))
  #echo "$line_count"

  # Check and rotate the file if necessary every X lines
  if [[ line_count -ge 50 ]] ; then
    line_count=0
    rotate_file "$filename" "$max_size" "$max_files"
  fi
done

# Rotate the file at the end, if necessary
rotate_file "$filename" "$max_size" "$max_files"
