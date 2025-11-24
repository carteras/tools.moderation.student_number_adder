#!/bin/bash

# =============================================================
# Student ID Recursive File Renamer
# Traverses all subdirectories and prefixes all found files with
# the specified Student ID: 'filename.ext' -> '01234567_filename.ext'
# =============================================================

# --- Configuration ---
# The Student ID is expected as the first argument ($1)
STUDENT_ID="$1"
DRY_RUN=true

# Check for required argument (Student ID)
if [[ -z "$STUDENT_ID" ]]; then
    echo "ERROR: Missing Student ID."
    echo "--------------------------------------------------------"
    echo "Usage: $0 <STUDENT_ID> [--run]"
    echo "Example (Dry Run): $0 01234567"
    echo "Example (Actual Run): $0 01234567 --run"
    echo "--------------------------------------------------------"
    exit 1
fi

# Check for run flag (expected as $2)
if [[ "$2" == "--run" ]]; then
    DRY_RUN=false
    echo "--- ACTUAL RENAMING MODE: Files will be modified ---"
    echo "Using Student ID: $STUDENT_ID (Applied recursively to all subfolders)"
    echo "Press ENTER to continue, or Ctrl+C to abort..."
    read
else
    echo "--- DRY RUN MODE: No changes will be made ---"
    echo "Using Student ID: $STUDENT_ID (Applied recursively to all subfolders)"
    echo "To execute the renaming, run the script with the '--run' flag."
fi
echo ""

# --- Renaming Logic ---
file_count=0

# Use 'find' to get a list of all files recursively (excluding directories)
# -print0 ensures safe handling of filenames with spaces or special characters.
find . -type f -print0 | while IFS= read -r -d $'\0' file_path; do
    
    # 1. Skip if the file is hidden or is the script itself
    if [[ "$file_path" == "./."* ]]; then
        continue
    fi
    if [[ "$file_path" == "$0" || "$file_path" == "./$0" ]]; then
        continue
    fi

    # 2. Get the directory path and the base filename
    # Example: file_path = ./Assignments/Essay/draft.docx
    dir_name=$(dirname "$file_path")   # -> ./Assignments/Essay
    base_name=$(basename "$file_path") # -> draft.docx

    # 3. Check if the file name already starts with the specific Student ID (to prevent double-renaming)
    # The regex check is applied only to the base filename.
    # Note: We escape the dot in the regex just in case the student ID contains one.
    if [[ "$base_name" =~ ^$(echo "$STUDENT_ID" | sed 's/\./\\./g')_ ]]; then
        echo "SKIP: File already prefixed in '$dir_name': '$base_name'"
        continue
    fi

    # 4. Construct the new base filename and the new full path
    new_base_name="${STUDENT_ID}_${base_name}"
    new_file_path="${dir_name}/${new_base_name}"

    if $DRY_RUN; then
        # Dry Run Output: Just print the action
        echo "DRY RUN: '$file_path' -> '$new_file_path'"
    else
        # Execute the rename operation using 'mv'
        # The '--' ensures filenames starting with a dash are treated as filenames, not options
        mv -- "$file_path" "$new_file_path"
        if [ $? -eq 0 ]; then
            echo "RENAMED: '$file_path' -> '$new_file_path'"
        else
            echo "ERROR: Failed to rename '$file_path'"
        fi
    fi

    # Increment the file counter
    file_count=$((file_count + 1))
done

# --- Final Summary ---
echo ""
echo "--- Finished processing $file_count files recursively. ---"

if $DRY_RUN; then
    echo "Run with '$0 $STUDENT_ID --run' to perform the actual changes."
fi

# Example:
# Run: ./rename_files.sh 01234567
# Before: 
# ./Assignment1/Draft.docx
# ./Assignment1/Images/Image.png
#
# After (if run): 
# ./Assignment1/01234567_Draft.docx
# ./Assignment1/Images/01234567_Image.png