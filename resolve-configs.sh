#!/usr/bin/env bash

set -euo pipefail

OS_NAME=$(uname -s)

case "$OS_NAME" in
  "Darwin")
    CONFIG_FILE_OS=".macos"
    ;;
  "Linux")
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]; then
        CONFIG_FILE_OS=".ubuntu"
      else
        CONFIG_FILE_OS=".linux"
      fi
    else
      CONFIG_FILE_OS=".linux"
    fi
    ;;
  *)
    echo "Warning: Unknown operating system '$OS_NAME'. No OS-specific Zsh config sourced."
    ;;
esac

if [[ -f shell-variables.env ]]; then
  source shell-variables.env
else
  echo "Error: env file 'shell-variables.env' not found."
  exit 1
fi

missing_vars=()

while IFS= read -r var_line; do
  [[ -z "$var_line" || "$var_line" =~ ^# ]] && continue
  var_name="${var_line%%=*}"

  value="${!var_name:-}"

  if [[ -z "$value" ]]; then
    missing_vars+=("$var_name")
  fi
done < shell-variables.env

if (( "${#missing_vars[@]}" > 0 )); then
  echo "Error: The following variables are empty in shell-variables.env:"
  for var in "${missing_vars[@]}"; do
    echo "  - $var"
  done
  exit 1
fi

function resolve_shell_configs() {
  local config_name="$1"
  local os_suffix="$2"
  local source_file=""
  local dest_file="$HOME/.${config_name}"

  if [[ -f "configs/${config_name}${os_suffix}" ]]; then
    source_file="configs/${config_name}${os_suffix}"
  elif [[ -f "configs/${config_name}" ]]; then
    source_file="configs/${config_name}"
  else
    echo "Warning: No source config file found for '${config_name}'. Skipping."
    return
  fi

  if [[ -f "$dest_file" ]]; then
    if diff -q "$source_file" "$dest_file" >/dev/null; then
      echo "No changes found for ${config_name}. Skipping update."
      return
    fi

    echo "Changes to be applied for ${config_name}:"
    diff --color=auto "$source_file" "$dest_file" || true

    local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    cp "$dest_file" "${dest_file}_old_$timestamp"
    echo "Created backup: ${dest_file}_old_$timestamp"

    cp "$source_file" "$dest_file"
    echo "Updated ${dest_file}."
  else
    cp "$source_file" "$dest_file"
    echo "Created new config file: ${dest_file}."
  fi

  source ${dest_file}
}

# Resolve and apply configurations
resolve_shell_configs zshrc "$CONFIG_FILE_OS"
resolve_shell_configs vimrc "$CONFIG_FILE_OS"
