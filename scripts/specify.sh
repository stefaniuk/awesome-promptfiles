#!/bin/bash

set -euo pipefail

# Fetch upstream spec-kit files and apply local extensions to produce
# patched files in the effective locations.
#
# Usage:
#   $ [options] ./scripts/specify.sh
#
# Options:
#   dry_run=true            # Show what would change without modifying files, default is 'false'
#   VERBOSE=true            # Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - All files patched successfully
#   1 - Error during patching
#
# Notes:
#   1) Requires the 'specify' CLI to be installed
#   2) Requires 'yq' for YAML parsing (falls back to defaults if not available)

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

EXTENSIONS_DIR="${REPO_ROOT}/.specify/extensions"
MANIFEST_FILE="${EXTENSIONS_DIR}/manifest.yaml"

# Target locations for patched files
TARGET_COMMANDS="${REPO_ROOT}/.claude/commands"
TARGET_AGENTS="${REPO_ROOT}/.github/agents"
TARGET_PROMPTS="${REPO_ROOT}/.github/prompts"
TARGET_TEMPLATES="${REPO_ROOT}/.specify/templates"

# Global variable for temp directory (used by trap)
TEMP_DIR=""

# ==============================================================================

# Main entry point for the patching workflow.
function main() {
  cd "${REPO_ROOT}"

  local dry_run=${dry_run:-false}

  echo "==> Fetching upstream spec-kit files..."
  TEMP_DIR=$(create-temp-directory)
  trap 'cleanup-temp-directory "$TEMP_DIR"' EXIT

  fetch-upstream-files "$TEMP_DIR"

  echo "==> Applying local extensions..."
  patch-category "$TEMP_DIR" "claude" "commands" ".claude/commands" "${TARGET_COMMANDS}" "speckit.*.md"
  patch-category "$TEMP_DIR" "copilot" "agents" ".github/agents" "${TARGET_AGENTS}" "speckit.*.agent.md"
  patch-category "$TEMP_DIR" "copilot" "prompts" ".github/prompts" "${TARGET_PROMPTS}" "speckit.*.prompt.md"
  patch-category "$TEMP_DIR" "" "templates" ".specify/templates" "${TARGET_TEMPLATES}" "*-template.md"

  if is-arg-true "$dry_run"; then
    echo "==> Dry run complete. No files were modified."
  else
    echo "==> Patching complete."
  fi

  return 0
}

# ==============================================================================

# Create a temporary directory for upstream files.
# Returns:
#   Path to the temporary directory (via stdout)
function create-temp-directory() {
  local temp_dir
  temp_dir=$(mktemp -d)
  echo "$temp_dir"
  return 0
}

# Clean up the temporary directory.
# Arguments:
#   $1=[path to temporary directory]
# shellcheck disable=SC2329
function cleanup-temp-directory() {
  local temp_dir="$1"
  if [[ -d "$temp_dir" ]]; then
    rm -rf "$temp_dir"
  fi
  return 0
}

# Fetch upstream spec-kit files using the specify CLI.
# Runs specify init for both copilot and claude AI tools so that
# all upstream artifacts are available for patching.
# Arguments:
#   $1=[path to temporary directory]
function fetch-upstream-files() {
  local temp_dir="$1"
  local ai_tools=("claude" "copilot")

  for ai_tool in "${ai_tools[@]}"; do
    (
      cd "$temp_dir"
      specify init \
        --ai "${ai_tool}" \
        --script sh \
        --ignore-agent-tools \
        --no-git \
        --here \
        --force \
        > /dev/null 2>&1
    )
  done

  return 0
}

# Patch a category of files (commands, agents, prompts, or templates).
# Arguments:
#   $1=[path to temporary directory]
#   $2=[AI tool name: claude, copilot, or empty for shared categories]
#   $3=[category name: commands, agents, prompts, or templates]
#   $4=[source subdirectory within temp dir]
#   $5=[target directory for patched files]
#   $6=[glob pattern for files to process]
function patch-category() {
  local temp_dir="$1"
  local ai_tool="$2"
  local category="$3"
  local source_subdir="$4"
  local target_dir="$5"
  local glob_pattern="$6"

  local source_dir="${temp_dir}/${source_subdir}"
  local extensions_subdir
  if [[ -n "${ai_tool}" ]]; then
    extensions_subdir="${EXTENSIONS_DIR}/${ai_tool}/${category}"
  else
    extensions_subdir="${EXTENSIONS_DIR}/${category}"
  fi
  local dry_run=${dry_run:-false}

  local display_name
  if [[ -n "${ai_tool}" ]]; then
    display_name="${ai_tool}/${category}"
  else
    display_name="${category}"
  fi
  echo "  [${display_name}]"

  if [[ ! -d "$source_dir" ]]; then
    echo "    Warning: Source directory not found: ${source_dir}"
    return 0
  fi

  # Ensure target directory exists
  if ! is-arg-true "$dry_run"; then
    mkdir -p "$target_dir"
  fi

  # Process each file matching the pattern
  local file
  for file in "${source_dir}"/${glob_pattern}; do
    if [[ ! -f "$file" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$file")
    local ext_file="${extensions_subdir}/${filename%.md}.ext.md"
    local target_file="${target_dir}/${filename}"

    if [[ -f "$ext_file" ]]; then
      patch-file "$file" "$ext_file" "$target_file" "$filename" "$ai_tool" "$category"
    else
      copy-file "$file" "$target_file" "$filename"
    fi
  done

  return 0
}

# Patch a single file by injecting the extension at the configured location.
# Arguments:
#   $1=[path to upstream file]
#   $2=[path to extension file]
#   $3=[path to target file]
#   $4=[filename for display]
#   $5=[AI tool name: claude, copilot, or empty for shared categories]
#   $6=[category name: commands, agents, prompts, or templates]
function patch-file() {
  local upstream_file="$1"
  local ext_file="$2"
  local target_file="$3"
  local filename="$4"
  local ai_tool="$5"
  local category="$6"

  local dry_run=${dry_run:-false}
  local injection_point

  injection_point=$(get-injection-point "$filename" "$ai_tool" "$category")

  echo "    Patching: ${filename} (injection: ${injection_point})"

  if is-arg-true "$dry_run"; then
    echo "      Would inject extension from: ${ext_file}"
    return 0
  fi

  local upstream_content
  local extension_content
  local extension_body
  local extension_footer
  local patched_content

  upstream_content=$(cat "$upstream_file")
  extension_content=$(cat "$ext_file")

  # Separate extension body from footer (footer starts with --- followed by version block)
  extension_body=$(extract-extension-body "$extension_content")
  extension_footer=$(extract-extension-footer "$extension_content")

  # Strip any existing footer from upstream content to avoid duplicates
  local upstream_body
  upstream_body=$(extract-extension-body "$upstream_content")

  # Inject extension body at the configured location
  patched_content=$(inject-extension "$upstream_body" "$extension_body" "$injection_point")

  # Append footer at the very end if present
  if [[ -n "$extension_footer" ]]; then
    patched_content=$(append-footer "$patched_content" "$extension_footer")
  fi

  echo "$patched_content" > "$target_file"

  return 0
}

# Copy a file without patching.
# Arguments:
#   $1=[path to source file]
#   $2=[path to target file]
#   $3=[filename for display]
function copy-file() {
  local source_file="$1"
  local target_file="$2"
  local filename="$3"

  local dry_run=${dry_run:-false}

  echo "    Copying:  ${filename} (no extension)"

  if is-arg-true "$dry_run"; then
    return 0
  fi

  cp "$source_file" "$target_file"

  return 0
}

# Get the injection point for a file from the manifest.
# Arguments:
#   $1=[filename]
#   $2=[AI tool name: claude, copilot, or empty for shared categories]
#   $3=[category name: commands, agents, prompts, or templates]
# Returns:
#   Injection point string (via stdout)
function get-injection-point() {
  local filename="$1"
  local ai_tool="$2"
  local category="$3"
  local default_injection="after-frontmatter"

  # Try to read from manifest if yq is available
  if command -v yq > /dev/null 2>&1 && [[ -f "$MANIFEST_FILE" ]]; then
    local override
    override=$(yq -r ".overrides.\"${filename}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    if [[ -n "$override" ]]; then
      echo "$override"
      return 0
    fi

    # Query category default from manifest using AI tool prefix
    local category_default=""
    if [[ -n "${ai_tool}" ]]; then
      category_default=$(yq -r ".defaults.\"${ai_tool}\".\"${category}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    else
      category_default=$(yq -r ".defaults.\"${category}\" // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
    fi

    if [[ -n "$category_default" ]]; then
      echo "$category_default"
      return 0
    fi
  fi

  echo "$default_injection"
  return 0
}

# Inject extension content into upstream content at the specified location.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[injection point]
# Returns:
#   Patched content (via stdout)
function inject-extension() {
  local upstream_content="$1"
  local extension_content="$2"
  local injection_point="$3"

  case "$injection_point" in
    after-frontmatter)
      inject-after-frontmatter "$upstream_content" "$extension_content"
      ;;
    before-section:*)
      local section_name="${injection_point#before-section:}"
      inject-before-section "$upstream_content" "$extension_content" "$section_name"
      ;;
    after-section:*)
      local section_name="${injection_point#after-section:}"
      inject-after-section "$upstream_content" "$extension_content" "$section_name"
      ;;
    append)
      inject-append "$upstream_content" "$extension_content"
      ;;
    prepend)
      inject-prepend "$upstream_content" "$extension_content"
      ;;
    *)
      # Default to after-frontmatter
      inject-after-frontmatter "$upstream_content" "$extension_content"
      ;;
  esac

  return 0
}

# Inject extension after YAML front matter (after the closing ---).
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-after-frontmatter() {
  local upstream_content="$1"
  local extension_content="$2"

  # Check if content starts with front matter delimiter
  if [[ "$upstream_content" =~ ^(\`\`\`[a-z]*$'\n')?--- ]]; then
    # Find the closing --- and inject after it
    local in_frontmatter=false
    local frontmatter_closed=false
    local code_fence=""
    local result=""

    while IFS= read -r line || [[ -n "$line" ]]; do
      result+="${line}"$'\n'

      # Handle code fence at start (```chatagent or ```prompt)
      if [[ -z "$code_fence" ]] && [[ "$line" =~ ^\`\`\`[a-z]+ ]]; then
        code_fence="$line"
        continue
      fi

      # Track front matter state
      if [[ "$line" == "---" ]]; then
        if ! $in_frontmatter; then
          in_frontmatter=true
        else
          # This is the closing ---
          if ! $frontmatter_closed; then
            frontmatter_closed=true
            result+=$'\n'"${extension_content}"$'\n'
          fi
        fi
      fi
    done <<< "$upstream_content"

    # Remove trailing newline added by loop
    result="${result%$'\n'}"
    echo "$result"
  else
    # No front matter, prepend extension
    echo "${extension_content}"$'\n'$'\n'"${upstream_content}"
  fi

  return 0
}

# Inject extension before a specific section heading.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function inject-before-section() {
  local upstream_content="$1"
  local extension_content="$2"
  local section_name="$3"

  local injected=false
  local result=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      result+="${extension_content}"$'\n'$'\n'
      injected=true
    fi
    result+="${line}"$'\n'
  done <<< "$upstream_content"

  # If section not found, append at end
  if ! $injected; then
    result+=$'\n'"${extension_content}"
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Inject extension after a specific section heading (and its first paragraph).
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
#   $3=[section heading to find]
# Returns:
#   Patched content (via stdout)
function inject-after-section() {
  local upstream_content="$1"
  local extension_content="$2"
  local section_name="$3"

  local found_section=false
  local injected=false
  local result=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    result+="${line}"$'\n'

    if ! $injected && [[ "$line" == "$section_name"* ]]; then
      found_section=true
    elif $found_section && ! $injected; then
      # Inject after the section heading line
      result+=$'\n'"${extension_content}"$'\n'
      injected=true
    fi
  done <<< "$upstream_content"

  # If section not found, append at end
  if ! $injected; then
    result+=$'\n'"${extension_content}"
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Append extension at the end of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-append() {
  local upstream_content="$1"
  local extension_content="$2"

  echo "${upstream_content}"$'\n'$'\n'"${extension_content}"

  return 0
}

# Prepend extension at the start of the file.
# Arguments:
#   $1=[upstream content]
#   $2=[extension content]
# Returns:
#   Patched content (via stdout)
function inject-prepend() {
  local upstream_content="$1"
  local extension_content="$2"

  echo "${extension_content}"$'\n'$'\n'"${upstream_content}"

  return 0
}

# Extract the body of an extension file (everything before the footer).
# The footer is identified by a line containing only "---" followed by
# (optional blank lines and) lines starting with "> **Version**:".
# Arguments:
#   $1=[extension content]
# Returns:
#   Extension body without footer (via stdout)
function extract-extension-body() {
  local content="$1"
  local result=""
  local footer_start_line=""
  local lines=()

  # Read content into array
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$content"

  local total_lines=${#lines[@]}

  # Scan backwards to find footer pattern: --- followed by (optional blank lines and) Version
  local i=$((total_lines - 1))
  while [[ $i -ge 0 ]]; do
    local line="${lines[$i]}"
    if [[ "$line" == "---" ]]; then
      # Skip blank lines after --- to find the first non-blank line
      local next_idx=$((i + 1))
      while [[ $next_idx -lt $total_lines ]] && [[ -z "${lines[$next_idx]}" ]]; do
        ((next_idx++))
      done
      if [[ $next_idx -lt $total_lines ]]; then
        local next_line="${lines[$next_idx]}"
        if [[ "$next_line" =~ ^\>\ \*\*Version\*\*: ]]; then
          footer_start_line=$i
          break
        fi
      fi
    fi
    ((i--))
  done

  # Output body (everything before footer)
  if [[ -n "$footer_start_line" ]]; then
    # Remove trailing blank lines before footer
    local end_idx=$((footer_start_line - 1))
    while [[ $end_idx -ge 0 ]] && [[ -z "${lines[$end_idx]}" ]]; do
      ((end_idx--))
    done
    for ((j = 0; j <= end_idx; j++)); do
      result+="${lines[$j]}"$'\n'
    done
  else
    # No footer found, return entire content
    result="$content"$'\n'
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Extract the footer from an extension file.
# The footer is identified by a line containing only "---" followed by
# (optional blank lines and) lines starting with "> **Version**:".
# Arguments:
#   $1=[extension content]
# Returns:
#   Footer content (via stdout), empty if no footer found
function extract-extension-footer() {
  local content="$1"
  local result=""
  local footer_start_line=""
  local lines=()

  # Read content into array
  while IFS= read -r line || [[ -n "$line" ]]; do
    lines+=("$line")
  done <<< "$content"

  local total_lines=${#lines[@]}

  # Scan backwards to find footer pattern: --- followed by (optional blank lines and) Version
  local i=$((total_lines - 1))
  while [[ $i -ge 0 ]]; do
    local line="${lines[$i]}"
    if [[ "$line" == "---" ]]; then
      # Skip blank lines after --- to find the first non-blank line
      local next_idx=$((i + 1))
      while [[ $next_idx -lt $total_lines ]] && [[ -z "${lines[$next_idx]}" ]]; do
        ((next_idx++))
      done
      if [[ $next_idx -lt $total_lines ]]; then
        local next_line="${lines[$next_idx]}"
        if [[ "$next_line" =~ ^\>\ \*\*Version\*\*: ]]; then
          footer_start_line=$i
          break
        fi
      fi
    fi
    ((i--))
  done

  # Output footer if found
  if [[ -n "$footer_start_line" ]]; then
    for ((j = footer_start_line; j < total_lines; j++)); do
      result+="${lines[$j]}"$'\n'
    done
  fi

  # Remove trailing newline
  result="${result%$'\n'}"
  echo "$result"

  return 0
}

# Append footer to the end of patched content.
# Arguments:
#   $1=[patched content]
#   $2=[footer content]
# Returns:
#   Content with footer appended (via stdout)
function append-footer() {
  local content="$1"
  local footer="$2"

  echo "${content}"$'\n'$'\n'"${footer}"

  return 0
}

# ==============================================================================

# Check if an argument is truthy (true, yes, y, on, 1).
# Arguments:
#   $1=[value to check]
# Returns:
#   0 if truthy, 1 otherwise
function is-arg-true() {
  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main "$@"

exit 0
