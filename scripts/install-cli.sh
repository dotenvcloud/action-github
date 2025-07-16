#!/bin/bash
set -e

# Script to install DotEnv CLI
# Usage: ./install-cli.sh [version]

VERSION="${1:-latest}"
INSTALL_DIR="$HOME/.dotenv/bin"
BINARY_NAME="dotenv"

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    i386|i686)
        ARCH="386"
        ;;
    armv7l)
        ARCH="arm"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Map OS names
case "$OS" in
    linux)
        OS="linux"
        EXT=""
        ;;
    darwin)
        OS="darwin"
        EXT=""
        ;;
    mingw*|msys*|cygwin*)
        OS="windows"
        EXT=".exe"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Installing DotEnv CLI for $OS/$ARCH..."

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Determine download URL
if [ "$VERSION" = "latest" ]; then
    # Get latest release URL from GitHub API
    RELEASE_URL="https://api.github.com/repos/dotenv/cli/releases/latest"
    
    # Use GitHub token if available for higher rate limits
    if [ -n "$GITHUB_TOKEN" ]; then
        DOWNLOAD_URL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$RELEASE_URL" | \
            grep "browser_download_url.*${OS}_${ARCH}" | \
            cut -d '"' -f 4 | \
            head -n 1)
    else
        DOWNLOAD_URL=$(curl -s "$RELEASE_URL" | \
            grep "browser_download_url.*${OS}_${ARCH}" | \
            cut -d '"' -f 4 | \
            head -n 1)
    fi
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Could not find download URL for $OS/$ARCH"
        echo "Falling back to direct download from dotenv.com..."
        DOWNLOAD_URL="https://dotenv.com/releases/cli/latest/dotenv_${OS}_${ARCH}${EXT}"
    fi
else
    # Use specific version
    DOWNLOAD_URL="https://github.com/dotenv/cli/releases/download/v${VERSION}/dotenv_${OS}_${ARCH}${EXT}"
fi

echo "Downloading from: $DOWNLOAD_URL"

# Download the binary
TEMP_FILE=$(mktemp)
if [ -n "$GITHUB_TOKEN" ]; then
    curl -L -H "Authorization: token $GITHUB_TOKEN" -o "$TEMP_FILE" "$DOWNLOAD_URL"
else
    curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"
fi

# Verify download
if [ ! -s "$TEMP_FILE" ]; then
    echo "Download failed or file is empty"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Move to installation directory
mv "$TEMP_FILE" "$INSTALL_DIR/${BINARY_NAME}${EXT}"
chmod +x "$INSTALL_DIR/${BINARY_NAME}${EXT}"

# Add to PATH for current session
export PATH="$INSTALL_DIR:$PATH"

# Verify installation
if command -v dotenv >/dev/null 2>&1; then
    echo "✅ DotEnv CLI installed successfully!"
    dotenv version
else
    echo "❌ Installation completed but 'dotenv' command not found"
    echo "You may need to add $INSTALL_DIR to your PATH"
    # For GitHub Actions, add to PATH
    echo "$INSTALL_DIR" >> $GITHUB_PATH
fi

# For GitHub Actions, ensure it's in PATH for next steps
if [ -n "$GITHUB_PATH" ]; then
    echo "$INSTALL_DIR" >> $GITHUB_PATH
fi