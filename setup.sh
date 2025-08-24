#!/bin/bash

# Dotfiles Setup Script
# This script automates the setup of Homebrew, Bitwarden, and chezmoi

# Self-extraction mechanism for interactive prompts
if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    echo "Script is being piped. Extracting to temp file for interactive execution..."
    
    # Script is being piped or not interactive, extract to temp file and run
    TEMP_SCRIPT=$(mktemp /tmp/setup_script_${RANDOM}_$(date +%s)_$$.sh)
    trap "rm -f $TEMP_SCRIPT" EXIT
    
    # Read the entire script from stdin and write to temp file
    cat > "$TEMP_SCRIPT"
    
    # Make it executable and run it with proper terminal redirection
    chmod +x "$TEMP_SCRIPT"
    echo "Executing temp script with terminal access..."
    
    # Run the script in a new bash process with terminal redirection
    bash "$TEMP_SCRIPT" < /dev/tty > /dev/tty 2>&1
    exit $?
fi

echo "Running setup script..."

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if we're on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
}

# Function to check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        exit 1
    fi
}

# Function to check internet connectivity
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_error "No internet connection detected. Please check your network."
        exit 1
    fi
}

# Function to setup Homebrew
setup_homebrew() {
    print_status "Setting up Homebrew..."
    
    if command_exists brew; then
        print_status "Homebrew is already installed. Updating..."
        brew update
        print_success "Homebrew updated successfully"
    else
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed successfully"
    fi
}

# Function to setup Bitwarden
setup_bitwarden() {
    print_status "Setting up Bitwarden..."
    
    # Install Bitwarden CLI
    if ! command_exists bw; then
        print_status "Installing Bitwarden CLI..."
        brew install bitwarden-cli
        print_success "Bitwarden CLI installed successfully"
    else
        print_status "Bitwarden CLI is already installed"
    fi
    
    # Configure Bitwarden server
    bw config server https://vault.bitwarden.eu
    
    # Check current login status
    print_status "Checking Bitwarden login status..."
    if bw status | grep -q "You are logged in!"; then
        print_success "Already logged in to Bitwarden"
    else
        print_status "Not logged in. Please log in to Bitwarden..."
        SESSION_KEY=$(bw login --raw || echo "")
    fi

    # Get session key and export it
    print_status "Getting Bitwarden session key..."
    
    if [[ -n "$SESSION_KEY" ]]; then
        export BW_SESSION="$SESSION_KEY"
        echo "export BW_SESSION=\"$SESSION_KEY\"" >> ~/.zprofile
        echo "export BW_SESSION=\"$SESSION_KEY\"" >> ~/.zshrc
        print_success "Bitwarden session key exported and saved to shell profiles"
        
        # Verify session key works
        print_status "Verifying session key..."
        if bw list folders --session "$SESSION_KEY" >/dev/null 2>&1; then
            print_success "Session key verified successfully"
        else
            print_warning "Session key verification failed. You may need to unlock manually."
        fi
    else
        print_warning "Could not automatically get session key. You may need to unlock manually:"
        print_status "Run: bw unlock"
        print_status "Then copy the session key and export it manually"
    fi
    
    # Try to unlock the vault and get session key
    print_status "Attempting to unlock Bitwarden vault..."
    if bw status | grep -q "\"locked\""; then
        print_warning "Bitwarden vault is locked. Please unlock it manually:"
        print_status "Run: bw unlock"
        print_status "Or unlock through the Bitwarden app"
        read -p "Press Enter after unlocking the vault..."
    fi
    
    print_success "Bitwarden setup completed"
    
    # Display final status
    print_status "Final Bitwarden status:"
    bw status
}

# Function to setup chezmoi
setup_chezmoi() {
    print_status "Setting up chezmoi..."
    
    # Check if chezmoi is already installed
    if command_exists chezmoi; then
        print_status "chezmoi is already installed"
    else
        print_status "Installing chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply styrmist
        print_success "chezmoi installed and initialized successfully"
    fi
}

# Function to display completion message
show_completion() {
    echo
    print_success "Setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Check chezmoi status: chezmoi status"
    echo "3. Apply any changes: chezmoi apply"
    echo
    print_status "Your system is now configured with:"
    echo "✓ Homebrew package manager"
    echo "✓ Bitwarden password manager"
    echo "✓ chezmoi dotfile manager"
    echo
}

# Main execution
main() {
    echo "=========================================="
    echo "    Dotfiles Setup Script"
    echo "=========================================="
    echo
    
    # Pre-flight checks
    print_status "Running pre-flight checks..."
    check_macos
    check_not_root
    check_internet
    print_success "Pre-flight checks passed"
    echo
    
    # Setup steps
    setup_homebrew
    echo
    
    setup_bitwarden
    echo
    
    setup_chezmoi
    echo
    
    show_completion
}

# Run main function
main "$@"
