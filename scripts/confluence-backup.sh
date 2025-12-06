#!/bin/zsh
set -euo pipefail

# Confluence Backup Script
# Exports Confluence pages and creates self-contained HTML files with embedded attachments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Default configuration
CONFIG_FILE="${CONFLUENCE_CONFIG:-$HOME/.secrets/confluence-export.yaml}"
ENV_FILE="${CONFLUENCE_ENV:-$HOME/.secrets/atlassian.env}"
OUTPUT_DIR="${1:-./confluence-backups}"
ORIGINAL_DIR="$OUTPUT_DIR/_original"

usage() {
    cat << EOF
Usage: $0 [output_directory]

Exports Confluence pages and creates self-contained HTML files.

Arguments:
  output_directory    Where to save HTML files (default: ./confluence-backups)

Output Structure:
  output_directory/SPACEKEY/           Organized by space
    └── Page Name/                     Each page is a folder
        └── index.html                 Self-contained HTML with embedded images
    └── Child Page/                    Nested structure preserved
        └── index.html
  output_directory/_original/          Original exports with separate attachments
    └── SPACEKEY/
        └── Page Name/
            ├── index.html             Original HTML
            └── attachments/           Separate attachment files

Environment Variables:
  CONFLUENCE_CONFIG   Path to YAML config (default: ~/.secrets/confluence-export.yaml)
  CONFLUENCE_ENV      Path to credentials (default: ~/.secrets/atlassian.env)

Examples:
  $0                                    # Export to ./confluence-backups
  $0 ~/Documents/confluence            # Export to specific directory
  $0 /Volumes/Backup/confluence        # Export to mounted volume

EOF
}

# Show help
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Verify configuration files
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "============================================"
echo "Confluence Backup"
echo "============================================"
echo "Config:  $CONFIG_FILE"
echo "Output:  $OUTPUT_DIR"
echo ""

# Step 1: Export Confluence pages
echo "Step 1: Exporting Confluence pages..."
echo "---"
"$SCRIPT_DIR/confluence-export.py" -c "$CONFIG_FILE" -e "$ENV_FILE" "$ORIGINAL_DIR"

if [[ $? -ne 0 ]]; then
    echo "Error: Confluence export failed"
    exit 1
fi

echo ""
echo "Step 2: Converting to self-contained HTML..."
echo "---"

# Convert to self-contained HTML files, mirroring _original structure
total=0
success=0
failed=0

while IFS= read -r -d '' html_file; do
    total=$((total + 1))
    
    # Get relative path from _original directory
    rel_path="${html_file#$ORIGINAL_DIR/}"
    dir_name=$(dirname "$rel_path")
    
    echo "[$total] $dir_name"
    
    # Mirror the _original structure exactly - every page is a folder with index.html
    output_file="$OUTPUT_DIR/$dir_name/index.html"
    mkdir -p "$(dirname "$output_file")"
    
    # Convert with pandoc
    (cd "$(dirname "$html_file")" && pandoc "$(basename "$html_file")" \
        --embed-resources --standalone -o "$output_file" 2>/dev/null) || true
    
    if [[ -f "$output_file" ]]; then
        file_size=$(ls -lh "$output_file" | awk '{print $5}')
        rel_output="${output_file#$OUTPUT_DIR/}"
        echo "    ✓ $rel_output ($file_size)"
        success=$((success + 1))
    else
        echo "    ✗ Failed"
        failed=$((failed + 1))
    fi
done < <(find "$ORIGINAL_DIR" -type f -name "index.html" -print0)

echo ""
echo "============================================"
echo "Summary: $success/$total successful"
echo "HTML:      $OUTPUT_DIR/ (organized by space)"
echo "Originals: $ORIGINAL_DIR/"
echo "============================================"

[[ $failed -eq 0 ]] && echo "✓ Complete" || exit 1