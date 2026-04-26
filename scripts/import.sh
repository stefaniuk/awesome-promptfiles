#!/bin/bash

set -euo pipefail

# Import changed prompt files from a destination repository back to this source.
# This is the inverse of apply.sh — it pulls improvements made in a project back.
#
# Usage:
#   $ [options] ./scripts/import.sh <source-directory> <ai-tool>
#
# Arguments:
#   source-directory        Project directory to import from (absolute or relative path)
#   ai-tool                 AI tool configuration to import: 'copilot' or 'claude'
#
# Options:
#   force=true              # Copy changed files without prompting, default is 'false'
#   new=true                # Also import new files that don't exist in source repo, default is 'false'
#   VERBOSE=true            # Show all the executed commands, default is 'false'
#
# Exit codes:
#   0 - Completed successfully
#   1 - Missing or invalid arguments
#
# Examples:
#   ./scripts/import.sh /path/to/my-project copilot
#   force=true ./scripts/import.sh ~/projects/my-app copilot
#   new=true force=true ./scripts/import.sh ~/projects/my-app copilot
#   ./scripts/import.sh ~/projects/my-app claude

# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Global arrays populated by collect-* functions
CHANGED_FILES=()
NEW_FILES=()

# ==============================================================================

# Main entry point for the script.
function main() {

  if [[ $# -ne 2 ]]; then
    print-usage
    exit 1
  fi

  if [[ -z "$1" ]]; then
    print-error "Source directory cannot be empty."
  fi

  local ai_tool="$2"
  if [[ "${ai_tool}" != "copilot" && "${ai_tool}" != "claude" ]]; then
    print-error "Invalid ai tool '${ai_tool}'. Must be 'copilot' or 'claude'."
  fi

  local source_dir
  source_dir=$(normalise-path "$1")

  if [[ ! -d "${source_dir}" ]]; then
    print-error "Source directory does not exist: ${source_dir}"
  fi

  echo "Importing prompt files from: ${source_dir} (ai=${ai_tool})"
  echo

  collect-changes "${source_dir}" "${ai_tool}"
  report-and-act "${source_dir}"

  return 0
}

# ==============================================================================

# Normalise a path — expand ~ and resolve relative paths.
# Arguments:
#   $1=[path]
function normalise-path() {

  local path="$1"

  path="${path//\\ / }"

  if [[ "${path}" == \~ ]]; then
    path="${HOME}"
  elif [[ "${path:0:2}" == \~/* ]]; then
    path="${HOME}/${path:2}"
  fi

  if [[ "${path}" != /* ]]; then
    local dir
    local dir_abs
    dir="$(dirname "${path}")"
    if dir_abs=$(cd "$(pwd)" && cd "${dir}" 2>/dev/null && pwd); then
      path="${dir_abs}/$(basename "${path}")"
    else
      path="$(pwd)/${path}"
    fi
  fi

  printf '%s\n' "${path}"

  return 0
}

# ==============================================================================

# Collect changed and new files for a given AI tool.
# Populates global CHANGED_FILES and NEW_FILES arrays.
# Arguments:
#   $1=[source directory]
#   $2=[ai tool: 'copilot' or 'claude']
function collect-changes() {

  local source_dir="$1"
  local ai_tool="$2"

  CHANGED_FILES=()
  NEW_FILES=()

  if [[ "${ai_tool}" == "copilot" ]]; then
    collect-copilot-changes "${source_dir}"
  elif [[ "${ai_tool}" == "claude" ]]; then
    collect-claude-changes "${source_dir}"
  fi

  collect-shared-changes "${source_dir}"

  return 0
}

# Collect changed and new copilot files.
# Appends to global CHANGED_FILES and NEW_FILES arrays.
# Arguments:
#   $1=[source directory]
function collect-copilot-changes() {

  local source_dir="$1"

  compare-file "${source_dir}" ".github/copilot-instructions.md"
  compare-directory-files "${source_dir}" ".github/agents" "*.md"
  compare-directory-files "${source_dir}" ".github/instructions" "*.instructions.md"
  compare-directory-recursive "${source_dir}" ".github/instructions/includes"
  compare-directory-files "${source_dir}" ".github/instructions/templates" "*"
  compare-directory-files "${source_dir}" ".github/prompts" "*.prompt.md"
  compare-directory-recursive "${source_dir}" ".github/skills"

  return 0
}

# Collect changed and new claude files.
# Appends to global CHANGED_FILES and NEW_FILES arrays.
# Arguments:
#   $1=[source directory]
function collect-claude-changes() {

  local source_dir="$1"

  compare-file "${source_dir}" ".claude/CLAUDE.md"
  compare-directory-files "${source_dir}" ".claude/commands" "*.md"

  return 0
}

# Collect changed and new shared resource files.
# Appends to global CHANGED_FILES and NEW_FILES arrays.
# Arguments:
#   $1=[source directory]
function collect-shared-changes() {

  local source_dir="$1"

  compare-file "${source_dir}" ".specify/memory/constitution.md"
  compare-directory-recursive "${source_dir}" ".specify/scripts/bash"
  compare-directory-recursive "${source_dir}" ".specify/templates"
  compare-file "${source_dir}" "docs/adr/ADR-nnn_Any_Decision_Record_Template.md"
  compare-file "${source_dir}" "docs/adr/Tech_Radar.md"
  compare-directory-recursive "${source_dir}" "docs/prompts"

  return 0
}

# ==============================================================================

# Check whether a managed path should be excluded from import.
# Arguments:
#   $1=[relative file path]
function is-ignored-import-path() {

  local path="$1"

  case "${path}" in
    .github/skills/repository-template/assets/*) return 0 ;;
  esac

  return 1
}

# ==============================================================================

# Compare a single file between source directory and repo.
# If the file differs, appends its relative path to CHANGED_FILES.
# If the file is missing in the repo, appends its relative path to NEW_FILES.
# Arguments:
#   $1=[source directory]
#   $2=[relative file path]
function compare-file() {

  local source_dir="$1"
  local rel_path="$2"

  local src_file="${source_dir}/${rel_path}"
  local repo_file="${REPO_ROOT}/${rel_path}"

  if is-ignored-import-path "${rel_path}"; then
    return 0
  fi

  if [[ -f "${src_file}" ]]; then
    if [[ -f "${repo_file}" ]]; then
      if ! diff -q "${src_file}" "${repo_file}" > /dev/null 2>&1; then
        CHANGED_FILES+=("${rel_path}")
      fi
    else
      NEW_FILES+=("${rel_path}")
    fi
  fi

  return 0
}

# Compare files in a directory (non-recursive) between source and repo.
# Appends changed files to CHANGED_FILES, new files to NEW_FILES.
# Arguments:
#   $1=[source directory]
#   $2=[relative directory path]
#   $3=[filename pattern for find -name]
function compare-directory-files() {

  local source_dir="$1"
  local rel_dir="$2"
  local pattern="$3"

  local src_dir="${source_dir}/${rel_dir}"
  local repo_dir="${REPO_ROOT}/${rel_dir}"

  if [[ ! -d "${src_dir}" ]]; then
    return 0
  fi

  local src_file
  while IFS= read -r -d '' src_file; do
    local bname
    bname=$(basename "${src_file}")
    local rel_path="${rel_dir}/${bname}"
    local repo_file="${repo_dir}/${bname}"

    if is-ignored-import-path "${rel_path}"; then
      continue
    fi

    if [[ -f "${repo_file}" ]]; then
      if ! diff -q "${src_file}" "${repo_file}" > /dev/null 2>&1; then
        CHANGED_FILES+=("${rel_path}")
      fi
    else
      NEW_FILES+=("${rel_path}")
    fi
  done < <(find "${src_dir}" -maxdepth 1 -name "${pattern}" -type f -print0 | sort -z)

  return 0
}

# Compare files recursively in a directory between source and repo.
# Appends changed files to CHANGED_FILES, new files to NEW_FILES.
# Arguments:
#   $1=[source directory]
#   $2=[relative directory path]
function compare-directory-recursive() {

  local source_dir="$1"
  local rel_dir="$2"

  local src_dir="${source_dir}/${rel_dir}"

  if [[ ! -d "${src_dir}" ]]; then
    return 0
  fi

  local src_file
  while IFS= read -r -d '' src_file; do
    local rel_path="${rel_dir}/${src_file#"${src_dir}/"}"
    local repo_file="${REPO_ROOT}/${rel_path}"

    if is-ignored-import-path "${rel_path}"; then
      continue
    fi

    if [[ -f "${repo_file}" ]]; then
      if ! diff -q "${src_file}" "${repo_file}" > /dev/null 2>&1; then
        CHANGED_FILES+=("${rel_path}")
      fi
    else
      NEW_FILES+=("${rel_path}")
    fi
  done < <(find "${src_dir}" -type f ! -name ".git" ! -path "*/.git/*" -print0 | sort -z)

  return 0
}

# ==============================================================================

# Report results and optionally copy files.
# Reads from global CHANGED_FILES and NEW_FILES arrays.
# Arguments:
#   $1=[source directory]
function report-and-act() {

  local source_dir="$1"
  local has_changes=false

  if [[ ${#CHANGED_FILES[@]} -gt 0 ]]; then
    has_changes=true
    echo "Changed files (${#CHANGED_FILES[@]}):"
    for f in "${CHANGED_FILES[@]}"; do
      echo "  M ${f}"
    done
    echo
  fi

  if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
    has_changes=true
    echo "New files in destination (${#NEW_FILES[@]}):"
    for f in "${NEW_FILES[@]}"; do
      echo "  A ${f}"
    done
    echo
  fi

  if [[ "${has_changes}" == "false" ]]; then
    echo "No changes detected."
    return 0
  fi

  if is-arg-true "${force:-false}"; then
    if [[ ${#CHANGED_FILES[@]} -gt 0 ]]; then
      echo "Importing changed files..."
      for f in "${CHANGED_FILES[@]}"; do
        copy-file-to-repo "${source_dir}" "${f}"
      done
    fi

    if is-arg-true "${new:-false}" && [[ ${#NEW_FILES[@]} -gt 0 ]]; then
      echo "Importing new files..."
      for f in "${NEW_FILES[@]}"; do
        copy-file-to-repo "${source_dir}" "${f}"
      done
    fi

    echo
    echo "Done."
  else
    echo "Run with force=true to import changed files."
    if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
      echo "Run with new=true to also import new files."
    fi
  fi

  return 0
}



# Copy a file from the source directory to the repo.
# Arguments:
#   $1=[source directory]
#   $2=[relative file path]
function copy-file-to-repo() {

  local source_dir="$1"
  local rel_path="$2"

  local src_file="${source_dir}/${rel_path}"
  local repo_file="${REPO_ROOT}/${rel_path}"
  local repo_dir
  repo_dir=$(dirname "${repo_file}")

  mkdir -p "${repo_dir}"
  cp "${src_file}" "${repo_file}"
  print-info "Copied ${rel_path}"

  return 0
}

# ==============================================================================

# Print usage information.
function print-usage() {

  cat <<EOF
Usage: $(basename "$0") <source-directory> <ai-tool>

Import changed prompt files from a project back to this source repository.

Arguments:
    source-directory        Project directory to import from (absolute or relative path)
    ai-tool                 AI tool configuration: 'copilot' or 'claude'

Options:
    force=true              Copy changed files without prompting (default: dry-run)
    new=true                Also import new files not in source repo
    VERBOSE=true            Show all executed commands

Examples:
    $(basename "$0") /path/to/my-project copilot
    force=true $(basename "$0") ~/projects/my-app copilot
    new=true force=true $(basename "$0") ~/projects/my-app copilot
    $(basename "$0") ~/projects/my-app claude
EOF
}

# Print an error message to stderr and exit.
# Arguments:
#   $1=[error message to display]
function print-error() {

  echo "Error: $1" >&2
  exit 1
}

# Print an informational message.
# Arguments:
#   $1=[message to display]
function print-info() {

  echo "→ $1"
}

# ==============================================================================

# Check if an argument is a truthy value.
# Arguments:
#   $1=[value to check]
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
