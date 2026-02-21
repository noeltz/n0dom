#!/usr/bin/env bash
set -e

# ============================================
# N0DOM Installer
# One-liner installation script for Arch Linux and Arch-based distributions
# Usage: curl -fsSL https://raw.githubusercontent.com/noeltz/n0dom/main/install.sh | bash
# ============================================

readonly N0DOM_VERSION="1.3.1"
readonly N0DOM_REPO="https://github.com/noeltz/n0dom"
readonly INSTALL_DIR="${HOME}/.local/bin"
readonly N0DOM_URL="${N0DOM_REPO}/raw/main/n0dom"

# Colors
readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly GREEN='\033[32m'
readonly RED='\033[31m'
readonly BLUE='\033[34m'
readonly YELLOW='\033[33m'

print_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

print_error() {
    echo -e "${RED}✗${RESET} $1" >&2
}

print_info() {
    echo -e "${BLUE}➜${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

# Detect if running on Arch Linux or Arch-based distribution
detect_arch_distro() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi
    
    # Source os-release to get variables
    local id=""
    local id_like=""
    
    while IFS='=' read -r key value; do
        # Remove quotes from value
        value="${value%\"}"
        value="${value#\"}"
        case "$key" in
            ID) id="$value" ;;
            ID_LIKE) id_like="$value" ;;
        esac
    done < /etc/os-release
    
    # Check if it's Arch or Arch-based
    # Arch-based distros typically have ID_LIKE containing "arch" or are "arch" itself
    if [[ "$id" == "arch" ]] || [[ "$id_like" == *"arch"* ]]; then
        return 0
    fi
    
    # Also check for pacman as a fallback (pacman is the definitive Arch package manager)
    if command -v pacman &> /dev/null; then
        return 0
    fi
    
    return 1
}

# Get distribution name for display
get_distro_name() {
    if [[ -f /etc/os-release ]]; then
        grep -E '^NAME=' /etc/os-release | cut -d'"' -f2 | head -1
    else
        echo "Unknown"
    fi
}

# Detect available package manager (pacman or AUR helper)
detect_package_manager() {
    # Check for AUR helpers first (they can install from AUR if needed)
    if command -v yay &> /dev/null; then
        echo "yay"
    elif command -v paru &> /dev/null; then
        echo "paru"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo ""
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Checking dependencies..."
    
    local missing=()
    local missing_aur=()
    
    # Required dependencies
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if ! command -v gh &> /dev/null; then
        # github-cli might be in AUR on some Arch-based distros
        missing+=("github-cli")
    fi
    
    # Optional but recommended dependencies - install automatically
    if ! command -v yq &> /dev/null; then
        print_info "yq not found, will install (recommended for config file support)"
        missing+=("yq")
    fi
    
    # meld is optional - ask user
    if ! command -v meld &> /dev/null; then
        print_info "meld is a graphical merge tool for conflict resolution"
        print_info "Other options: vimdiff (included with vim), code (VS Code)"
        read -p "Install meld? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            missing+=("meld")
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_info "Installing dependencies: ${missing[*]}"
        
        local pkg_manager
        pkg_manager=$(detect_package_manager)
        
        if [[ -z "$pkg_manager" ]]; then
            print_error "No package manager found (pacman/yay/paru)"
            print_info "Please install manually: ${missing[*]}"
            exit 1
        fi
        
        print_info "Installing with: $pkg_manager"
        
        case "$pkg_manager" in
            yay|paru)
                # AUR helpers can install both repo and AUR packages
                $pkg_manager -S --noconfirm "${missing[@]}" || {
                    print_warning "AUR install may have failed, trying pacman for repo packages..."
                    # Fallback: install what we can with pacman
                    sudo pacman -S --noconfirm "${missing[@]}" 2>/dev/null || true
                }
                ;;
            pacman)
                sudo pacman -S --noconfirm "${missing[@]}" || {
                    print_error "Failed to install dependencies with pacman"
                    print_info "If any package is not in your repos, you may need an AUR helper (yay/paru)"
                    exit 1
                }
                ;;
        esac
        
        print_success "All dependencies installed"
    else
        print_success "All dependencies satisfied"
    fi
}

# Download n0dom
download_n0dom() {
    print_info "Downloading n0dom..."
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Download
    local temp_file
    temp_file=$(mktemp)
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$N0DOM_URL" -o "$temp_file"
    elif command -v wget &> /dev/null; then
        wget -q "$N0DOM_URL" -O "$temp_file"
    else
        print_error "Neither curl nor wget found. Cannot download n0dom."
        exit 1
    fi
    
    # Verify download
    if [[ ! -s "$temp_file" ]]; then
        print_error "Download failed or file is empty"
        exit 1
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Install
    mv "$temp_file" "${INSTALL_DIR}/n0dom"
    print_success "n0dom installed to ${INSTALL_DIR}/n0dom"
}

# Update PATH
update_path() {
    local shell_rc=""
    
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh" ]]; then
        shell_rc="${HOME}/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash" ]]; then
        shell_rc="${HOME}/.bashrc"
    fi
    
    # Check if PATH already contains .local/bin
    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        print_warning "${INSTALL_DIR} is not in your PATH"
        
        if [[ -n "$shell_rc" ]]; then
            print_info "Adding ${INSTALL_DIR} to PATH in ${shell_rc}"
            echo '' >> "$shell_rc"
            echo '# Add n0dom to PATH' >> "$shell_rc"
            echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "$shell_rc"
            print_success "PATH updated in ${shell_rc}"
            print_info "Please run: source ${shell_rc}"
        else
            print_info "Add this to your shell configuration:"
            echo "export PATH=\"\${HOME}/.local/bin:\${PATH}\""
        fi
    fi
}

# Main installation
main() {
    echo -e "${BOLD}N0DOM Installer v${N0DOM_VERSION}${RESET}"
    echo
    
    # Detect distro
    if detect_arch_distro; then
        local distro_name
        distro_name=$(get_distro_name)
        print_success "Detected Arch-based distribution: $distro_name"
    else
        print_warning "This installer is designed for Arch Linux and Arch-based distributions"
        print_info "Detected: $(get_distro_name)"
        print_info "n0dom may work on other distributions, but dependencies must be installed manually"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Check for pacman or AUR helper
    local pkg_manager
    pkg_manager=$(detect_package_manager)
    if [[ -n "$pkg_manager" ]]; then
        print_info "Package manager detected: $pkg_manager"
    else
        print_warning "No package manager detected (pacman/yay/paru)"
    fi
    
    # Install
    install_dependencies
    download_n0dom
    update_path
    
    # Verify installation
    echo
    if command -v n0dom &> /dev/null; then
        print_success "Installation complete!"
        echo
        echo -e "${BOLD}Getting Started:${RESET}"
        echo "  n0dom init              Create a new dotfiles repository"
        echo "  n0dom clone <repo>      Restore from an existing repository"
        echo "  n0dom help              Show all commands"
        echo
        echo "Visit ${N0DOM_REPO} for more information"
    else
        print_success "Installation complete!"
        echo
        echo "Please restart your terminal or run:"
        echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
        echo "  n0dom help"
    fi
}

main "$@"
