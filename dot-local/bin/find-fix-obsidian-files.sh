#!/bin/bash

# Cubbit S3 Version Recovery Script
# This script detects and optionally restores files that may have been accidentally deleted or shrunk

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENDPOINT="https://s3.cubbit.eu"
ODDITIES_FILE="oddities.txt"
EXCLUDE_PATTERNS=()

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --exclude PATTERN       Exclude files matching pattern (can be used multiple times)
                           Examples: --exclude "0-Inbox/" --exclude "temp/"
    --ignore-pattern PATTERN  (alias for --exclude)
    -h, --help             Show this help message

Examples:
    $0
    $0 --exclude "0-Inbox/" --exclude ".trash/"
    $0 --ignore-pattern "drafts/" --ignore-pattern "temp/"
EOF
  exit 0
}

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --exclude | --ignore-pattern)
      if [[ -z "${2:-}" ]]; then
        print_error "Argument for $1 is missing"
        exit 1
      fi
      EXCLUDE_PATTERNS+=("$2")
      shift 2
      ;;
    -h | --help)
      show_usage
      ;;
    *)
      print_error "Unknown option: $1"
      show_usage
      ;;
    esac
  done
}

# Function to check if a key should be excluded
is_excluded() {
  local key="$1"

  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [[ "$key" == "$pattern"* ]]; then
      return 0 # true, is excluded
    fi
  done

  return 1 # false, not excluded
}

# Function to check if AWS CLI is installed
check_prerequisites() {
  if ! command -v aws &>/dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    print_info "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    print_error "jq is not installed. Please install it first."
    print_info "On macOS: brew install jq"
    print_info "On Ubuntu/Debian: sudo apt-get install jq"
    print_info "On RHEL/CentOS: sudo yum install jq"
    exit 1
  fi
}

# Function to get credentials
get_credentials() {
  print_info "Please provide your Cubbit S3 credentials:"

  read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
  read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
  echo
  read -p "Bucket Name: " BUCKET_NAME

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY

  # Verify credentials
  print_info "Verifying credentials..."
  if ! aws s3api --endpoint "$ENDPOINT" head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    print_error "Failed to access bucket. Please check your credentials and bucket name."
    exit 1
  fi

  print_success "Credentials verified successfully!"
}

# Function to check if versioning is enabled
check_versioning() {
  print_info "Checking if versioning is enabled on bucket..."

  local status
  status=$(aws s3api --endpoint "$ENDPOINT" get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "")

  if [[ "$status" != "Enabled" ]]; then
    print_error "Bucket versioning is not enabled. This script requires versioning."
    exit 1
  fi

  print_success "Versioning is enabled!"
}

# Function to get ETag for a specific version
get_version_etag() {
  local key="$1"
  local version_id="$2"

  aws s3api --endpoint "$ENDPOINT" head-object \
    --bucket "$BUCKET_NAME" \
    --key "$key" \
    --version-id "$version_id" \
    --query 'ETag' \
    --output text 2>/dev/null | tr -d '"' || echo ""
}

# Function to build content hash map (size+etag -> key mapping)
build_content_map() {
  print_info "Building content map to detect file moves..."

  # Create associative array: "size:etag" -> "key"
  declare -gA CONTENT_MAP

  # Get all current versions (IsLatest = true)
  local current_files
  current_files=$(jq -r '.Versions[] | select(.IsLatest == true) | 
        {Key, Size, ETag, VersionId} | @json' /tmp/versions.json)

  while IFS= read -r file; do
    local key size etag version_id
    key=$(echo "$file" | jq -r '.Key')
    size=$(echo "$file" | jq -r '.Size')
    etag=$(echo "$file" | jq -r '.ETag' | tr -d '"')
    version_id=$(echo "$file" | jq -r '.VersionId')

    # Skip excluded files
    if is_excluded "$key"; then
      continue
    fi

    local content_hash="${size}:${etag}"
    CONTENT_MAP["$content_hash"]="$key"
  done <<<"$current_files"

  print_success "Content map built with ${#CONTENT_MAP[@]} unique files"
}

# Function to check if a deleted file was likely moved (not truly deleted)
was_file_moved() {
  local deleted_key="$1"
  local deleted_version_id="$2"
  local deleted_size="$3"

  # Get ETag of the deleted version
  local deleted_etag
  deleted_etag=$(get_version_etag "$deleted_key" "$deleted_version_id")

  if [[ -z "$deleted_etag" ]]; then
    return 1 # Can't determine, assume not moved
  fi

  local content_hash="${deleted_size}:${deleted_etag}"

  # Check if this content exists elsewhere
  if [[ -n "${CONTENT_MAP[$content_hash]:-}" ]]; then
    local current_location="${CONTENT_MAP[$content_hash]}"

    # If it exists at a different location, it was moved
    if [[ "$current_location" != "$deleted_key" ]]; then
      echo "$current_location" # Return new location
      return 0                 # true, was moved
    fi
  fi

  return 1 # false, not moved
}

# Function to analyze all object versions
analyze_versions() {
  print_info "Retrieving all object versions from bucket..."

  # Clear the oddities file
  >"$ODDITIES_FILE"

  local has_oddities=false
  local total_objects=0
  local checked_objects=0
  local excluded_count=0
  local moved_count=0

  # Get all object versions
  aws s3api --endpoint "$ENDPOINT" list-object-versions --bucket "$BUCKET_NAME" --output json >/tmp/versions.json

  # Build content map for move detection
  build_content_map

  # Count unique keys
  total_objects=$(jq -r '.Versions[]?.Key // empty' /tmp/versions.json | sort -u | wc -l)
  print_info "Found $total_objects unique objects to analyze..."

  if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
    print_info "Excluding patterns: ${EXCLUDE_PATTERNS[*]}"
  fi

  # Extract unique keys to a temp file to avoid subshell issues
  jq -r '.Versions[]?.Key // empty' /tmp/versions.json | sort -u >/tmp/unique_keys.txt

  # Process each unique key
  while IFS= read -r key; do
    ((checked_objects++))
    printf "\rAnalyzing: %d/%d objects" "$checked_objects" "$total_objects"

    # Check if this key should be excluded
    if is_excluded "$key"; then
      ((excluded_count++))
      continue
    fi

    # Get all versions for this key, sorted by LastModified (newest first)
    local versions
    versions=$(jq -r --arg key "$key" '.Versions[] | select(.Key == $key) | 
            {VersionId, Size, LastModified, IsLatest, ETag} | @json' /tmp/versions.json)

    # Parse versions into arrays
    local version_ids=()
    local sizes=()
    local dates=()
    local is_latest=()
    local etags=()

    while IFS= read -r version; do
      version_ids+=("$(echo "$version" | jq -r '.VersionId')")
      sizes+=("$(echo "$version" | jq -r '.Size')")
      dates+=("$(echo "$version" | jq -r '.LastModified')")
      is_latest+=("$(echo "$version" | jq -r '.IsLatest')")
      etags+=("$(echo "$version" | jq -r '.ETag' | tr -d '"')")
    done <<<"$versions"

    # Skip if no versions found
    [[ ${#version_ids[@]} -eq 0 ]] && continue

    # Find the current version (IsLatest = true)
    local current_idx=-1
    for i in "${!is_latest[@]}"; do
      if [[ "${is_latest[$i]}" == "true" ]]; then
        current_idx=$i
        break
      fi
    done

    # Check for deleted files (delete marker as current version)
    if [[ $current_idx -eq -1 ]]; then
      # Check if file was moved instead of deleted
      local new_location
      if new_location=$(was_file_moved "$key" "${version_ids[0]}" "${sizes[0]}"); then
        ((moved_count++))
        # File was moved, not deleted - skip it
        continue
      fi

      # No current version means there's a delete marker and it wasn't moved
      has_oddities=true
      echo "DELETED|$key|${version_ids[0]}|${sizes[0]}|${dates[0]}" >>"$ODDITIES_FILE"
      continue
    fi

    # Check for size reduction (current version smaller than any previous version)
    local current_size=${sizes[$current_idx]}
    local found_larger=false
    local best_version_idx=-1
    local largest_size=0

    for i in "${!sizes[@]}"; do
      if [[ $i -ne $current_idx ]] && [[ ${sizes[$i]} -gt $current_size ]]; then
        found_larger=true
        if [[ ${sizes[$i]} -gt $largest_size ]]; then
          largest_size=${sizes[$i]}
          best_version_idx=$i
        fi
      fi
    done

    if [[ $found_larger == true ]]; then
      has_oddities=true
      echo "SHRUNK|$key|${version_ids[$current_idx]}|$current_size|${dates[$current_idx]}|${version_ids[$best_version_idx]}|$largest_size|${dates[$best_version_idx]}" >>"$ODDITIES_FILE"
    fi

  done </tmp/unique_keys.txt

  echo # New line after progress
  echo # Extra newline for readability

  print_success "Analysis complete! Processed $checked_objects objects."

  if [[ $excluded_count -gt 0 ]]; then
    print_info "Excluded $excluded_count file(s) based on patterns"
  fi

  if [[ $moved_count -gt 0 ]]; then
    print_info "Detected $moved_count file(s) that were moved (not deleted)"
  fi

  local oddities_count=0
  if [[ -s "$ODDITIES_FILE" ]]; then
    oddities_count=$(wc -l <"$ODDITIES_FILE")
  fi

  if [[ $oddities_count -eq 0 ]]; then
    print_success "No issues found! All files appear to be intact."
    print_info "Your Obsidian vault looks healthy."
    rm -f /tmp/versions.json /tmp/unique_keys.txt "$ODDITIES_FILE"
    exit 0
  fi

  print_warning "Found $oddities_count potential issue(s) - see details below."
}

# Function to display oddities
display_oddities() {
  local deleted_count=$(grep -c "^DELETED|" "$ODDITIES_FILE" 2>/dev/null || echo 0)
  local shrunk_count=$(grep -c "^SHRUNK|" "$ODDITIES_FILE" 2>/dev/null || echo 0)

  print_warning "Found issues with $((deleted_count + shrunk_count)) file(s):"
  echo

  if [[ $deleted_count -gt 0 ]]; then
    print_warning "Deleted files ($deleted_count):"
    echo "------------------------------------------------"
    while IFS='|' read -r type key version_id size date; do
      if [[ "$type" == "DELETED" ]]; then
        echo "  File: $key"
        echo "    Last size: $size bytes"
        echo "    Deleted: $date"
        echo "    Recoverable version: $version_id"
        echo
      fi
    done <"$ODDITIES_FILE"
  fi

  if [[ $shrunk_count -gt 0 ]]; then
    print_warning "Files that shrunk in size ($shrunk_count):"
    echo "------------------------------------------------"
    while IFS='|' read -r type key curr_ver curr_size curr_date prev_ver prev_size prev_date; do
      if [[ "$type" == "SHRUNK" ]]; then
        echo "  File: $key"
        echo "    Current: $curr_size bytes (version: $curr_ver, date: $curr_date)"
        echo "    Previous: $prev_size bytes (version: $prev_ver, date: $prev_date)"
        echo "    Size difference: $((prev_size - curr_size)) bytes"
        echo
      fi
    done <"$ODDITIES_FILE"
  fi
}

# Function to prompt for review
prompt_review() {
  print_info "Results saved to: $ODDITIES_FILE"
  echo
  print_warning "REVIEW THE FILE CAREFULLY!"
  echo "You can:"
  echo "  1. Remove lines for files you DON'T want to restore"
  echo "  2. Keep lines for files you DO want to restore"
  echo
  read -p "Press ENTER when you're ready to continue with restoration..."
}

# Function to restore files
restore_files() {
  if [[ ! -s "$ODDITIES_FILE" ]]; then
    print_info "No files to restore (oddities.txt is empty)."
    exit 0
  fi

  local total_lines=$(wc -l <"$ODDITIES_FILE")
  local current_line=0
  local restored=0
  local failed=0

  print_info "Starting restoration process for $total_lines file(s)..."
  echo

  while IFS='|' read -r type key rest; do
    ((current_line++))

    if [[ "$type" == "DELETED" ]]; then
      # Format: DELETED|key|version_id|size|date
      IFS='|' read -r _ _ version_id _ _ <<<"DELETED|$key|$rest"

      print_info "[$current_line/$total_lines] Restoring deleted file: $key"

      # Copy the old version to make it current
      if aws s3api --endpoint "$ENDPOINT" copy-object \
        --copy-source "$BUCKET_NAME/$key?versionId=$version_id" \
        --bucket "$BUCKET_NAME" \
        --key "$key" &>/dev/null; then
        print_success "  ✓ Restored from version $version_id"
        ((restored++))
      else
        print_error "  ✗ Failed to restore"
        ((failed++))
      fi

    elif [[ "$type" == "SHRUNK" ]]; then
      # Format: SHRUNK|key|curr_ver|curr_size|curr_date|prev_ver|prev_size|prev_date
      IFS='|' read -r _ _ _ _ _ prev_ver _ _ <<<"SHRUNK|$key|$rest"

      print_info "[$current_line/$total_lines] Restoring shrunk file: $key"

      # Copy the larger version to make it current
      if aws s3api --endpoint "$ENDPOINT" copy-object \
        --copy-source "$BUCKET_NAME/$key?versionId=$prev_ver" \
        --bucket "$BUCKET_NAME" \
        --key "$key" &>/dev/null; then
        print_success "  ✓ Restored from version $prev_ver"
        ((restored++))
      else
        print_error "  ✗ Failed to restore"
        ((failed++))
      fi
    fi
  done <"$ODDITIES_FILE"

  echo
  print_success "Restoration complete!"
  print_info "Successfully restored: $restored file(s)"
  [[ $failed -gt 0 ]] && print_warning "Failed to restore: $failed file(s)"
}

# Main execution
main() {
  echo
  echo "╔════════════════════════════════════════════════╗"
  echo "║   Cubbit S3 Version Recovery Script           ║"
  echo "╚════════════════════════════════════════════════╝"
  echo

  # Parse arguments
  parse_args "$@"

  # Check prerequisites
  check_prerequisites

  # Get credentials
  get_credentials

  # Check versioning
  check_versioning

  # Analyze versions
  analyze_versions

  # Display oddities
  display_oddities

  # Prompt for review
  prompt_review

  # Restore files
  restore_files

  # Cleanup
  rm -f /tmp/versions.json /tmp/unique_keys.txt

  echo
  print_success "All done!"
}

# Run main function
main "$@"
