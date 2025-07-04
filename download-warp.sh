#!/bin/bash

# Script to download the latest version of Warp Terminal for Linux
# Automatically detects whether to download .deb or .rpm based on the distribution

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly TEMP_DIR="${TMPDIR:-/tmp}"
readonly DOWNLOAD_DIR="${DOWNLOAD_DIR:-$(pwd)}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Global variables
OS=""
VER=""
ARCH=""
PACKAGE_TYPE=""
DOWNLOAD_URL=""
FILENAME=""
TEMP_FILE=""

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

# Cleanup function
cleanup() {
    if [[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]]; then
        rm -f "${TEMP_FILE}"
        print_info "Cleaned up temporary file"
    fi
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Function to detect system architecture
detect_architecture() {
    local machine
    machine="$(uname -m)"
    
    case "${machine}" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            print_error "Unsupported architecture: ${machine}"
            print_info "Warp Terminal currently supports x86_64/amd64 and arm64 architectures"
            exit 1
            ;;
    esac
}

# Function to detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="${ID}"
        VER="${VERSION_ID:-unknown}"
    elif command -v lsb_release >/dev/null 2>&1; then
        OS="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
        VER="$(lsb_release -sr)"
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS="$(echo "${DISTRIB_ID}" | tr '[:upper:]' '[:lower:]')"
        VER="${DISTRIB_RELEASE}"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        VER="$(cat /etc/debian_version)"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        if command -v rpm >/dev/null 2>&1; then
            VER="$(rpm -q --qf "%{VERSION}" "$(rpm -q --whatprovides redhat-release)")"
        else
            VER="unknown"
        fi
    else
        OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
        VER="$(uname -r)"
    fi
}

# Function to determine package type
get_package_type() {
    case "${OS}" in
        ubuntu|debian|pop|linuxmint|elementary|kali|parrot|deepin|zorin|raspbian)
            echo "deb"
            ;;
        fedora|rhel|centos|rocky|almalinux|opensuse*|sles|oracle|amzn)
            echo "rpm"
            ;;
        arch|manjaro|endeavouros|garuda)
            print_error "Arch-based distributions are not officially supported by Warp Terminal"
            print_info "You may want to check AUR for community packages"
            exit 1
            ;;
        *)
            print_error "Unknown distribution: ${OS}"
            print_info "Please manually download from https://www.warp.dev/"
            exit 1
            ;;
    esac
}

# Function to check if file exists and prompt for overwrite
check_existing_file() {
    local filepath="$1"
    
    if [[ -f "${filepath}" ]]; then
        print_warning "File already exists: ${filepath}"
        read -rp "Overwrite? (y/N): " -n 1 reply
        echo
        if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
            print_info "Download cancelled"
            exit 0
        fi
    fi
}

# Function to download file with progress
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -L --fail --progress-bar -o "${output}" "${url}" || return 1
    elif command -v wget &> /dev/null; then
        wget --show-progress -O "${output}" "${url}" || return 1
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Function to verify downloaded file
verify_download() {
    local file="$1"
    
    if [[ ! -f "${file}" ]]; then
        print_error "Download failed - file not found"
        return 1
    fi
    
    local size
    size="$(stat -c%s "${file}" 2>/dev/null || stat -f%z "${file}" 2>/dev/null || echo 0)"
    
    if [[ "${size}" -lt 1000000 ]]; then  # Less than 1MB
        print_error "Downloaded file seems too small (${size} bytes)"
        return 1
    fi
    
    print_info "Downloaded file size: $(numfmt --to=iec-i --suffix=B "${size}" 2>/dev/null || echo "${size} bytes")"
    return 0
}

# Main script
main() {
    print_info "Warp Terminal Downloader v1.1"
    
    # Check write permissions
    if [[ ! -w "${DOWNLOAD_DIR}" ]]; then
        print_error "No write permission in directory: ${DOWNLOAD_DIR}"
        exit 1
    fi
    
    # Detect system
    print_info "Detecting system configuration..."
    detect_architecture
    detect_distro
    
    print_info "Detected: ${OS} ${VER} (${ARCH})"
    
    # Determine package type
    PACKAGE_TYPE="$(get_package_type)"
    print_info "Package type: .${PACKAGE_TYPE}"
    
    # Set download parameters based on package type and architecture
    if [[ "${PACKAGE_TYPE}" = "deb" ]]; then
        if [[ "${ARCH}" = "arm64" ]]; then
            DOWNLOAD_URL="https://app.warp.dev/download?package=deb&arch=aarch64"
            FILENAME="warp-terminal_latest_arm64.deb"
        else
            DOWNLOAD_URL="https://app.warp.dev/download?package=deb"
            FILENAME="warp-terminal_latest_amd64.deb"
        fi
    elif [[ "${PACKAGE_TYPE}" = "rpm" ]]; then
        if [[ "${ARCH}" = "arm64" ]]; then
            DOWNLOAD_URL="https://app.warp.dev/download?package=rpm&arch=aarch64"
            FILENAME="warp-terminal_latest_aarch64.rpm"
        else
            DOWNLOAD_URL="https://app.warp.dev/download?package=rpm"
            FILENAME="warp-terminal_latest_x86_64.rpm"
        fi
    fi
    
    # Full path for the file
    local filepath="${DOWNLOAD_DIR}/${FILENAME}"
    
    # Check if file already exists
    check_existing_file "${filepath}"
    
    # Create temporary file for download
    TEMP_FILE="${TEMP_DIR}/${FILENAME}.tmp.$$"
    
    # Download the package
    print_info "Downloading Warp Terminal..."
    print_info "URL: ${DOWNLOAD_URL}"
    print_info "Saving to: ${filepath}"
    echo
    
    if download_file "${DOWNLOAD_URL}" "${TEMP_FILE}"; then
        # Verify download
        if verify_download "${TEMP_FILE}"; then
            # Move to final location
            mv "${TEMP_FILE}" "${filepath}"
            print_info "Download completed successfully!"
            print_info "File saved as: ${filepath}"
            
            # Provide installation instructions
            echo
            print_info "To install Warp Terminal:"
            if [[ "${PACKAGE_TYPE}" = "deb" ]]; then
                echo "  sudo dpkg -i \"${filepath}\""
                echo "  # If you encounter dependency issues, run:"
                echo "  sudo apt-get install -f"
            elif [[ "${PACKAGE_TYPE}" = "rpm" ]]; then
                echo "  # Using dnf (Fedora/RHEL 8+):"
                echo "  sudo dnf install \"${filepath}\""
                echo "  # Using yum (older systems):"
                echo "  sudo yum install \"${filepath}\""
                echo "  # Using rpm directly:"
                echo "  sudo rpm -i \"${filepath}\""
            fi
            
            # Optional: Verify package info
            echo
            print_info "To verify package info before installing:"
            if [[ "${PACKAGE_TYPE}" = "deb" ]]; then
                echo "  dpkg -I \"${filepath}\""
            elif [[ "${PACKAGE_TYPE}" = "rpm" ]]; then
                echo "  rpm -qip \"${filepath}\""
            fi
        else
            exit 1
        fi
    else
        print_error "Download failed!"
        exit 1
    fi
}

# Run main function
main "$@"