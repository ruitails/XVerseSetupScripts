#!/bin/bash

# Simple connection test script
# This will help debug the SSH connection issues

echo "Testing SSH connection to first remote machine..."
echo "Command: sshpass -p 'seame' ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no seame@100.77.8.52 'echo Connection successful'"
echo ""

# Test the connection
sshpass -p 'seame' ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no seame@100.77.8.52 'echo Connection successful'

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SSH connection successful!"
else
    echo ""
    echo "✗ SSH connection failed!"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if the remote machine is accessible:"
    echo "   ping 100.77.8.52"
    echo ""
    echo "2. Check if SSH service is running on the remote machine"
    echo ""
    echo "3. Verify the username and password are correct"
    echo ""
    echo "4. Check firewall settings on the remote machine"
    echo ""
    echo "5. Try connecting manually:"
    echo "   ssh -p 22 seame@100.77.8.52"
fi
