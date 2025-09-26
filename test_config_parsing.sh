#!/bin/bash

# Configuration file parser test
# This will help debug the parsing issues

CONFIG_FILE="Deployment/remotes.conf"

echo "Testing configuration file parsing..."
echo "File: $CONFIG_FILE"
echo ""

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

echo "Configuration file contents:"
echo "=========================="
cat -n "$CONFIG_FILE"
echo "=========================="
echo ""

echo "Parsing each line:"
echo "=================="

line_number=0
while IFS= read -r line; do
    line_number=$((line_number + 1))
    
    # Skip comments and empty lines
    if [[ $line =~ ^#.*$ ]] || [[ -z "$line" ]] || [[ $line =~ ^[[:space:]]*$ ]]; then
        echo "Line $line_number: SKIPPED (comment/empty)"
        continue
    fi
    
    echo "Line $line_number: '$line'"
    
    # Test parsing
    if [[ $line =~ ^([^@]+)@([^:]+):([0-9]+):(.+):(.+)$ ]]; then
        user="${BASH_REMATCH[1]}"
        host="${BASH_REMATCH[2]}"
        port="${BASH_REMATCH[3]}"
        remote_path="${BASH_REMATCH[4]}"
        password="${BASH_REMATCH[5]}"
        echo "  ✓ Parsed successfully:"
        echo "    User: $user"
        echo "    Host: $host"
        echo "    Port: $port"
        echo "    Path: $remote_path"
        echo "    Password: [HIDDEN]"
    else
        echo "  ✗ Parse failed - invalid format"
    fi
    echo ""
    
done < "$CONFIG_FILE"
