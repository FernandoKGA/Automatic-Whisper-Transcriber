#!/bin/bash

# Check if the user provided the base document name as an argument
if [[ -z "$1" ]]; then
    echo "Usage: $0 <document_name>"
    exit 1
fi

# Base document name received as argument
document_name="$1"

# Get the current directory where the script was called from
current_dir="$(pwd)"

# Final output file name
output_file="${current_dir}/${document_name}.txt"

# List existing files matching the expected pattern and sort them correctly
files=($(ls "${current_dir}/${document_name}.wav-part"*.txt 2>/dev/null | sort -V))

# Check if any files were found
if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files found for '${document_name}' in directory '${current_dir}'."
    exit 1
fi

# Clear the output file if it already exists
> "$output_file"

# Concatenate found files
for part_file in "${files[@]}"; do
    echo "Adding ${part_file} to the final file..."
    cat "$part_file" >> "$output_file"
    echo -e "\n" >> "$output_file" # Add a newline between parts
done

echo "Concatenation complete! Final file: $output_file"
