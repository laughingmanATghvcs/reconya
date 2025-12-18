#!/bin/bash

# reconYa Installation Script
# Checks for Node.js/npm prerequisites and runs installation

set -e  # Exit on any error

echo "==========================================="
echo "      reconYa Installation Script"
echo "==========================================="
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Node.js
if ! command_exists node; then
    echo "❌ Node.js is not installed"
    echo
    echo "Please install Node.js 18+ first:"
    echo "  • Visit: https://nodejs.org/"
    echo "  • Or use your package manager:"
    echo "    - Ubuntu/Debian: sudo apt update && sudo apt install nodejs npm"
    echo "    - RHEL/CentOS/Fedora: sudo yum install nodejs npm"
    echo "    - macOS: brew install node"
    echo
    echo "Then run this script again."
    exit 1
fi

# Check for npm
if ! command_exists npm; then
    echo "❌ npm is not installed"
    echo
    echo "Please install npm:"
    echo "  • Usually comes with Node.js installation"
    echo "  • Or install separately: sudo apt install npm"
    echo
    echo "Then run this script again."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | sed 's/v//')
REQUIRED_VERSION="18.0.0"

version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if ! version_ge "$NODE_VERSION" "$REQUIRED_VERSION"; then
    echo "❌ Node.js version $NODE_VERSION is too old"
    echo "   Required: Node.js 18.0.0 or higher"
    echo
    echo "Please update Node.js and try again."
    exit 1
fi

# All checks passed
echo "✅ Node.js $(node -v) detected"
echo "✅ npm $(npm -v) detected"
echo

echo "Starting reconYa installation..."
echo

# Install npm dependencies first
echo "Step 1: Installing npm dependencies..."
npm install

# Run reconYa installation
echo
echo "Step 2: Running reconYa installation..."
npm run install

echo
echo "==========================================="
echo "   Installation completed successfully!"
echo "==========================================="
echo