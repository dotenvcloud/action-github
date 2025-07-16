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

# Checksum verification (when available)
if [ "$VERSION" = "latest" ] && [ -n "$GITHUB_TOKEN" ]; then
    # Try to download checksums file
    CHECKSUMS_URL="${DOWNLOAD_URL%.tar.gz}.sha256"
    CHECKSUMS_URL="${CHECKSUMS_URL%_${OS}_${ARCH}${EXT}}_checksums.txt"
    
    echo "Attempting to download checksums from: $CHECKSUMS_URL"
    
    if curl -s -f -L -H "Authorization: token $GITHUB_TOKEN" "$CHECKSUMS_URL" > /tmp/checksums.txt 2>/dev/null; then
        # Extract expected checksum for our file
        EXPECTED_CHECKSUM=$(grep "${OS}_${ARCH}" /tmp/checksums.txt | cut -d' ' -f1)
        
        if [ -n "$EXPECTED_CHECKSUM" ]; then
            # Calculate actual checksum
            if command -v sha256sum >/dev/null 2>&1; then
                ACTUAL_CHECKSUM=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
            elif command -v shasum >/dev/null 2>&1; then
                ACTUAL_CHECKSUM=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
            else
                echo "⚠️  Warning: No SHA256 tool available for checksum verification"
                ACTUAL_CHECKSUM=""
            fi
            
            # Compare checksums
            if [ -n "$ACTUAL_CHECKSUM" ]; then
                if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
                    echo "✅ Checksum verification passed"
                else
                    echo "❌ Checksum verification failed!"
                    echo "   Expected: $EXPECTED_CHECKSUM"
                    echo "   Actual:   $ACTUAL_CHECKSUM"
                    rm -f "$TEMP_FILE"
                    exit 1
                fi
            fi
        else
            echo "⚠️  Warning: No checksum found for ${OS}_${ARCH}"
        fi
        
        rm -f /tmp/checksums.txt
    else
        echo "⚠️  Warning: Checksums file not available - skipping verification"
        echo "   For production use, ensure checksums are published with releases"
    fi
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
    echo ""
    echo "Troubleshooting:"
    echo "  - Installation directory: $INSTALL_DIR"
    echo "  - Binary location: $INSTALL_DIR/${BINARY_NAME}${EXT}"
    echo "  - Current PATH: $PATH"
    echo ""
    echo "For GitHub Actions, the directory has been added to GITHUB_PATH for future steps."
    echo "For local testing, add this to your shell configuration:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    
    # Check if the binary exists
    if [ -f "$INSTALL_DIR/${BINARY_NAME}${EXT}" ]; then
        echo ""
        echo "Binary exists at expected location. This is likely a PATH issue."
        ls -la "$INSTALL_DIR/${BINARY_NAME}${EXT}"
    else
        echo ""
        echo "ERROR: Binary not found at expected location!"
        exit 1
    fi
fi

# For GitHub Actions, ensure it's in PATH for next steps
if [ -n "$GITHUB_PATH" ]; then
    echo "$INSTALL_DIR" >> $GITHUB_PATH
fi