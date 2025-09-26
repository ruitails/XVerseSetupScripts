# XVerse Scripts

This repository contains individual bash scripts for setting up various tools and environments on Ubuntu 22.04 LTS systems.

## Scripts

### Cuttlefish Installation Script

The `Cuttlefish/install_cuttlefish.sh` script installs the Cuttlefish Android emulator on Ubuntu 22.04 LTS.

#### Prerequisites

- Ubuntu 22.04 LTS
- KVM support enabled in BIOS/UEFI
- User with sudo privileges
- Internet connection

#### Usage

1. Place your Cuttlefish artifacts (tarball and zip files) in the `Cuttlefish/artifacts/` directory
2. Navigate to the `Cuttlefish` directory
3. Run the installation script:

```bash
cd Cuttlefish
./install_cuttlefish.sh
```

#### What the script does

1. **Checks KVM support** - Verifies that virtualization features are available
2. **Installs dependencies** - Installs required packages (git, devscripts, equivs, etc.)
3. **Clones and builds Cuttlefish** - Downloads and compiles the Android Cuttlefish emulator
4. **Installs packages** - Installs the compiled Cuttlefish packages
5. **Configures user groups** - Adds the user to kvm, cvdnetwork, and render groups
6. **Extracts artifacts** - Creates `~/cf/` directory and extracts provided artifacts
7. **Prompts for reboot** - Offers to reboot the system for changes to take effect

#### Important Notes

- The script must be run from within the `Cuttlefish` directory
- The `artifacts/` directory must contain your tarball and zip files
- A reboot is required after installation for group changes to take effect
- The script will create a `~/cf/` directory in the user's home folder

#### Directory Structure

```
Cuttlefish/
├── install_cuttlefish.sh    # Main installation script
└── artifacts/               # Place your tarball and zip files here
    ├── your_file.tar.gz     # Your tarball file
    └── your_file.zip        # Your zip file
```

### Deployment Script

The `Deployment/deploy_cuttlefish.sh` script allows you to deploy the Cuttlefish installation script and artifacts to multiple remote Ubuntu machines simultaneously.

#### Prerequisites

- rsync installed (`sudo apt install rsync`)
- SSH key authentication set up for passwordless access to remote machines
- Remote machines running Ubuntu 22.04 LTS
- Write permissions to the specified remote paths

#### Usage

1. **Configure remote machines**:
   ```bash
   cp Deployment/remotes.conf.example Deployment/remotes.conf
   # Edit remotes.conf with your actual remote machine details
   ```

2. **Place artifacts** in the `Cuttlefish/artifacts/` directory

3. **Run the deployment script**:
   ```bash
   cd Deployment
   ./deploy_cuttlefish.sh [config_file]
   ```

#### Configuration Format

The configuration file uses the format: `user@hostname:port:remote_path`

Example entries:
```
ubuntu@192.168.1.100:22:/home/ubuntu
admin@server1.example.com:2222:/opt/cuttlefish
user@10.0.0.50:22:/home/user/XVerse
```

#### What the deployment script does

1. **Validates configuration** - Checks config file and source files
2. **Creates remote directories** - Sets up the directory structure on each remote
3. **Syncs install script** - Copies the installation script to each remote
4. **Syncs artifacts** - Copies all artifacts to each remote machine
5. **Sets permissions** - Makes the install script executable on remotes
6. **Provides summary** - Shows success/failure status for each remote

#### Important Notes

- The script runs sequentially for safety (one remote at a time)
- SSH key authentication is required for passwordless access
- The script will create the necessary directory structure on remote machines
- After deployment, you can SSH to each remote and run the installation script

#### Directory Structure

```
Deployment/
├── deploy_cuttlefish.sh      # Main deployment script
├── remotes.conf              # Configuration file (copy from example)
└── remotes.conf.example      # Example configuration file
```

## Contributing

When adding new scripts, please:

1. Create a dedicated directory for each script
2. Include a README section explaining the script's purpose and usage
3. Follow the same structure as the Cuttlefish script
4. Test scripts on clean Ubuntu 22.04 LTS installations
5. Include error handling and user-friendly messages

## License

This project is provided as-is for internal use.
