#!/bin/bash
if [ "$#" -ge 1 ]; then
  folder="$1"
else
  folder="resources/templates"
fi

# Get files that are completely missing (have delete markers)
echo "Getting files with delete markers..."
aws s3api --profile cubbit --endpoint https://s3.cubbit.eu list-object-versions \
  --bucket vaults \
  --query 'DeleteMarkers[].Key' \
  --prefix "$folder" \
  --output text | sort >/tmp/deleted_files.txt

# Get all currently existing files (any folder)
echo "Getting all current files..."
aws s3api --profile cubbit --endpoint https://s3.cubbit.eu list-objects-v2 \
  --bucket vaults \
  --query 'Contents[].Key' \
  --prefix "$folder" \
  --output text | sort >/tmp/all_current_files.txt

# Extract just the filename (without path) from both lists
echo "Analyzing..."
cat /tmp/deleted_files.txt | sed 's|.*/||' | sort >/tmp/deleted_filenames.txt
cat /tmp/all_current_files.txt | sed 's|.*/||' | sort >/tmp/current_filenames.txt

# Find files that are deleted and don't exist anywhere else with the same filename
echo "Files that are truly missing (not moved to other folders):"
comm -23 /tmp/deleted_filenames.txt /tmp/current_filenames.txt |
  while read filename; do
    # Show the original path of the missing file
    grep "/$filename$\|^$filename$" /tmp/deleted_files.txt
  done

echo -e "\nFiles that might have been moved (deleted from original location but exist elsewhere):"
comm -12 /tmp/deleted_filenames.txt /tmp/current_filenames.txt |
  while read filename; do
    echo "Filename: $filename"
    echo "  Was at: $(grep "/$filename$\|^$filename$" /tmp/deleted_files.txt)"
    echo "  Now at: $(grep "/$filename$\|^$filename$" /tmp/all_current_files.txt)"
    echo ""
  done

echo -n "Remove temp files? [y/N] "
read -r remove
shopt -s nocasematch
if [ "${remove}" = "y" ]; then
  echo "Removing files..."
  rm /tmp/deleted_files.txt /tmp/all_current_files.txt /tmp/deleted_filenames.txt /tmp/current_filenames.txt
fi
shopt -u nocasematch

# Retores files in a folder
# FOURTEEN_DAYS_AGO=$(date -d '14 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z)
#
# aws s3api --profile cubbit --endpoint https://s3.cubbit.eu list-object-versions \
# --bucket vaults --query "Versions[?IsLatest==\`false\` && LastModified>=\`$FOURTEEN_DAYS_AGO\`].[Key,VersionId,LastModified]" \
# --output text --prefix "resources/templates" | sort -k1,1 -k3,3r | awk '!seen[$1]++'| \
# while IFS=$'\t' read -r key version modified; do
#     echo "Restoring $key (version: $version)"
#     aws s3api --profile cubbit --endpoint https://s3.cubbit.eu copy-object \
#         --bucket vaults \
#         --copy-source "vaults/${key}?versionId=${version}" \
#         --key "$key" \
#         --metadata-directive REPLACE \
#         --metadata "original-modified-date=$modified"
# done
