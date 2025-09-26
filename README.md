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

## Contributing

When adding new scripts, please:

1. Create a dedicated directory for each script
2. Include a README section explaining the script's purpose and usage
3. Follow the same structure as the Cuttlefish script
4. Test scripts on clean Ubuntu 22.04 LTS installations
5. Include error handling and user-friendly messages

## License

This project is provided as-is for internal use.
