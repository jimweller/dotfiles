#!/usr/bin/env bash
# Install asdf plugins from manifests/asdf-plugins.txt
# Usage: ./scripts/asdf-plugins.sh

set -euo pipefail

# Check if asdf is available
if ! command -v asdf &> /dev/null; then
    echo "Error: asdf is not available. Please ensure asdf is installed and initialized."
    exit 1
fi

# Path to plugins manifest
PLUGINS_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/manifests/asdf-plugins.txt"

if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo "Error: Plugin manifest not found at $PLUGINS_FILE"
    exit 1
fi

echo "Installing asdf plugins from $PLUGINS_FILE"
echo "============================================"

# Read and process each line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Parse plugin name and URL
    plugin_name=$(echo "$line" | awk '{print $1}')
    plugin_url=$(echo "$line" | awk '{print $2}')
    
    echo ""
    echo "Processing: $plugin_name"
    
    # Check if plugin is already installed
    if asdf plugin list | grep -q "^${plugin_name}$"; then
        echo "  ✓ Plugin already installed: $plugin_name"
    else
        echo "  + Installing plugin: $plugin_name from $plugin_url"
        if asdf plugin add "$plugin_name" "$plugin_url"; then
            echo "  ✓ Successfully installed: $plugin_name"
        else
            echo "  ✗ Failed to install: $plugin_name"
        fi
    fi
done < "$PLUGINS_FILE"

echo ""
echo "============================================"
echo "Plugin installation complete!"
echo ""
echo "Next steps:"
echo "  1. Run: asdf install"
echo "  2. This will install all versions specified in ~/.tool-versions"