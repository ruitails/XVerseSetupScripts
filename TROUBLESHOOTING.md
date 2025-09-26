# Troubleshooting Guide for XVerse Deployment Script

## Issue: SSH Connection Failures

### Problem Analysis
The deployment script is failing to connect to remote machines. This is likely due to one of the following issues:

1. **sshpass not available on Windows** - The script requires `sshpass` for password authentication
2. **Network connectivity issues** - Remote machines may not be accessible
3. **SSH service not running** - SSH daemon may not be running on remote machines
4. **Authentication issues** - Username/password may be incorrect

### Solutions

#### Option 1: Run on Ubuntu Machine (Recommended)
The deployment script is designed for Ubuntu 22.04 LTS. Run it on an Ubuntu machine:

```bash
# Install dependencies
sudo apt update
sudo apt install rsync sshpass

# Clone the repository
git clone https://github.com/ruitails/XVerseSetupScripts.git
cd XVerseSetupScripts

# Test connections
cd Deployment
./test_connections.sh remotes.conf --password

# Deploy if connections work
./deploy_cuttlefish.sh remotes.conf --password
```

#### Option 2: Use WSL (Windows Subsystem for Linux)
If you have WSL installed:

```bash
# In WSL terminal
sudo apt update
sudo apt install rsync sshpass

# Navigate to your project
cd /mnt/c/Users/ruteixei/OneDrive\ -\ Capgemini/Desktop/Workspace/XVerse/XVerseScripts

# Test connections
cd Deployment
./test_connections.sh remotes.conf --password
```

#### Option 3: Manual Testing
Test each connection manually:

```bash
# Test basic connectivity
ping 100.77.8.52

# Test SSH connection
ssh -p 22 seame@100.77.8.52

# Test with password (if sshpass is available)
sshpass -p 'seame' ssh -p 22 seame@100.77.8.52 "echo Connection successful"
```

### Common Issues and Solutions

#### 1. "sshpass: command not found"
**Solution**: Install sshpass
```bash
sudo apt install sshpass
```

#### 2. "Connection refused"
**Possible causes**:
- SSH service not running on remote machine
- Firewall blocking SSH connections
- Wrong port number

**Solutions**:
```bash
# On remote machine, check SSH service
sudo systemctl status ssh
sudo systemctl start ssh

# Check if SSH is listening on port 22
sudo netstat -tlnp | grep :22
```

#### 3. "Permission denied"
**Possible causes**:
- Wrong username or password
- SSH key authentication required instead of password
- User account locked

**Solutions**:
- Verify username and password
- Check if password authentication is enabled in SSH config
- Try SSH key authentication instead

#### 4. "Host key verification failed"
**Solution**: Add `-o StrictHostKeyChecking=no` to SSH commands (already included in script)

### Configuration File Format
Ensure your `remotes.conf` has the correct format:

```
# Password Authentication Format: user@hostname:port:remote_path:password
seame@100.77.8.52:22:/home/seame:seame
seame@100.116.60.68:22:/home/seame:seame
```

### Testing Steps

1. **Test single connection**:
   ```bash
   ./test_single_connection.sh
   ```

2. **Test configuration parsing**:
   ```bash
   ./test_config_parsing.sh
   ```

3. **Test all connections**:
   ```bash
   ./test_connections.sh remotes.conf --password
   ```

4. **Deploy if all tests pass**:
   ```bash
   ./deploy_cuttlefish.sh remotes.conf --password
   ```

### Next Steps

1. Run the deployment script on an Ubuntu machine
2. Ensure all remote machines have SSH service running
3. Verify network connectivity between machines
4. Test with a single machine first before deploying to all
