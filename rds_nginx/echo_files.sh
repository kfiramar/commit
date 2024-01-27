#!/bin/bash

# Find all files in the current directory and its subdirectories
find . -type f | while read file; do
    # Check if the file is a text file
    if file "$file" | grep -q 'text'; then
        # Print the file name
        echo "==== $file ===="
        # Print the content of the file
        cat "$file"
        echo # Add a new line for readability
    fi
done
