# Warp Terminal Downloader

A robust bash script to automatically download the latest version of Warp Terminal for Linux, with automatic distribution and architecture detection.

## Features

- **Automatic OS Detection**: Detects your Linux distribution and downloads the appropriate package format (.deb or .rpm)
- **Architecture Support**: Supports both x86_64/amd64 and ARM64/aarch64 architectures
- **Safety Features**:
  - Prompts before overwriting existing files
  - Downloads to temporary file first, then moves to final location
  - Verifies download size to ensure completeness
  - Cleanup on interruption (Ctrl+C)
- **Progress Indicators**: Shows download progress using curl/wget
- **Comprehensive Error Handling**: Clear error messages and proper exit codes

## Usage

```bash
# Make the script executable
chmod +x download-warp.sh

# Run the script
./download-warp.sh

# Or download to a specific directory
DOWNLOAD_DIR=/path/to/directory ./download-warp.sh
```

## Supported Distributions

### Debian-based (.deb)
- Ubuntu
- Debian
- Pop!_OS
- Linux Mint
- Elementary OS
- Kali Linux
- Parrot OS
- Deepin
- Zorin OS
- Raspberry Pi OS

### RPM-based (.rpm)
- Fedora
- RHEL (Red Hat Enterprise Linux)
- CentOS
- Rocky Linux
- AlmaLinux
- openSUSE
- SLES
- Oracle Linux
- Amazon Linux

### Not Supported
- Arch Linux and derivatives (check AUR for community packages)

## Requirements

- Bash 4.0 or higher
- Either `curl` or `wget` installed
- Write permissions in the download directory

## Environment Variables

- `DOWNLOAD_DIR`: Directory to save the downloaded file (default: current directory)
- `TMPDIR`: Temporary directory for downloads (default: /tmp)

## Installation Instructions

After downloading, the script will provide installation commands specific to your distribution:

### For Debian-based systems:
```bash
sudo dpkg -i warp-terminal_latest_amd64.deb
# If you encounter dependency issues:
sudo apt-get install -f
```

### For RPM-based systems:
```bash
# Using dnf (Fedora/RHEL 8+):
sudo dnf install warp-terminal_latest_x86_64.rpm

# Using yum (older systems):
sudo yum install warp-terminal_latest_x86_64.rpm

# Using rpm directly:
sudo rpm -i warp-terminal_latest_x86_64.rpm
```

## Script Details

The script follows bash best practices:
- Strict error handling with `set -euo pipefail`
- Quoted variables to prevent word splitting
- Cleanup trap for temporary files
- POSIX-compatible where possible
- Clear function separation and documentation

## License

This download script is provided as-is for convenience. Warp Terminal itself is subject to its own license terms available at https://www.warp.dev/

## Contributing

Feel free to submit issues or pull requests if you encounter problems or have improvements to suggest.