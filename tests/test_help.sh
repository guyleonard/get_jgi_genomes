#!/usr/bin/env bash

# Run the help command and capture output
output=$(./bin/get_jgi_genomes -h 2>&1)
status=$?

# Check that exit status is zero
if [ $status -ne 0 ]; then
  echo "Expected exit status 0, got $status" >&2
  echo "$output" >&2
  exit 1
fi

# Check that output contains 'Usage:'
if ! echo "$output" | grep -q "Usage:"; then
  echo "Help output missing 'Usage:'" >&2
  echo "$output" >&2
  exit 1
fi

exit 0
