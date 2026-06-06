#!/bin/bash
set -e

# Script to install the DotEnv CLI
# Usage: ./install-cli.sh [version]
#   version: "latest" (default), "nightly", an exact version ("1.2.3"),
#            or a partial version ("1" → newest 1.x.x, "1.2" → newest 1.2.x)
#
# Resolves the real release asset published by GoReleaser
# (dotenv-cli_<version>_<os>_<arch>.tar.gz / .zip), verifies its
# SHA-256 against the published checksums.txt, extracts it, and
# installs the inner `dotenv` binary.

VERSION="${1:-latest}"
INSTALL_DIR="$HOME/.dotenv/bin"
BINARY_NAME="dotenv"
REPO="dotenvcloud/cli"
PROJECT_NAME="dotenv-cli"   # GoReleaser project_name → asset prefix

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Map architecture names to GoReleaser's GOARCH values
case "$ARCH" in
    x86_64)        ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    i386|i686)     ARCH="386" ;;
    armv7l)        ARCH="arm" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Map OS names and pick the archive format GoReleaser produces
case "$OS" in
    linux)            OS="linux";   ARCHIVE_EXT="tar.gz"; BIN_EXT="" ;;
    darwin)           OS="darwin";  ARCHIVE_EXT="tar.gz"; BIN_EXT="" ;;
    mingw*|msys*|cygwin*)
                      OS="windows"; ARCHIVE_EXT="zip";    BIN_EXT=".exe" ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

echo "Installing DotEnv CLI ($VERSION) for $OS/$ARCH..."

mkdir -p "$INSTALL_DIR"

# curl helper that adds the GitHub token when present (higher rate limits
# and access to private release assets).
gh_api() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -sSL -H "Authorization: token $GITHUB_TOKEN" "$1"
    else
        curl -sSL "$1"
    fi
}
gh_download() {
    # $1 = url, $2 = output path
    # Accept: application/octet-stream makes the GitHub asset API url return the
    # raw asset bytes (required for private-repo release assets); it is harmless
    # for plain browser_download_url / direct-host downloads.
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fSL -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/octet-stream" -o "$2" "$1"
    else
        curl -fSL -H "Accept: application/octet-stream" -o "$2" "$1"
    fi
}

# Resolve the release metadata endpoint for the requested version.
# Supports: latest, nightly, an exact version (1.2.3), or a partial version
# (1 → newest stable 1.x.x, 1.2 → newest stable 1.2.x).
case "$VERSION" in
    latest)
        RELEASE_API="https://api.github.com/repos/${REPO}/releases/latest"
        ;;
    nightly)
        RELEASE_API="https://api.github.com/repos/${REPO}/releases/tags/nightly"
        ;;
    *)
        REQ="${VERSION#v}"
        if echo "$REQ" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
            # Exact version — resolve the tag directly (single API call).
            RELEASE_API="https://api.github.com/repos/${REPO}/releases/tags/v${REQ}"
        elif echo "$REQ" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
            # Partial version (e.g. "1" or "1.2") — pick the newest STABLE
            # release whose tag starts with "v${REQ}." Sorting is numeric per
            # component so 1.10.0 ranks above 1.9.0.
            if ! command -v jq >/dev/null 2>&1; then
                echo "❌ Partial version matching ('$VERSION') requires 'jq'. Specify a full version like 1.2.3."
                exit 1
            fi
            echo "Resolving newest stable release matching ${REQ}.x ..."
            RELEASES_JSON="$(gh_api "https://api.github.com/repos/${REPO}/releases?per_page=100" || true)"
            RESOLVED="$(echo "$RELEASES_JSON" | jq -r --arg p "v${REQ}." '
                [ (.[]? )
                  | select(.prerelease == false and .draft == false)
                  | .tag_name
                  | select(startswith($p))
                  | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
                ]
                | map(ltrimstr("v") | split(".") | map(tonumber))
                | sort | .[]
                | "v" + (map(tostring) | join("."))
            ' 2>/dev/null | tail -n 1)"
            if [ -z "$RESOLVED" ]; then
                echo "❌ No stable release matching ${REQ}.x found for ${REPO}"
                exit 1
            fi
            echo "Matched '${VERSION}' → ${RESOLVED}"
            VERSION="${RESOLVED#v}"   # concrete version, for any fallback naming
            RELEASE_API="https://api.github.com/repos/${REPO}/releases/tags/${RESOLVED}"
        else
            echo "❌ Invalid cli-version: '${VERSION}' (use 'latest', 'nightly', or a version like 1, 1.2, or 1.2.3)"
            exit 1
        fi
        ;;
esac

# Asset name suffix we expect, e.g. _linux_amd64.tar.gz
ASSET_SUFFIX="_${OS}_${ARCH}.${ARCHIVE_EXT}"

echo "Resolving release from: $RELEASE_API"
RELEASE_JSON="$(gh_api "$RELEASE_API" || true)"

DOWNLOAD_URL=""
CHECKSUMS_URL=""
ARCHIVE_NAME=""
if [ -n "$RELEASE_JSON" ]; then
    if command -v jq >/dev/null 2>&1; then
        # The asset API url works for private repos (with a token) and public
        # repos alike; browser_download_url 404s for private release assets.
        ARCHIVE_NAME="$(echo "$RELEASE_JSON" | jq -r --arg s "$ASSET_SUFFIX" '(.assets // [])[] | select(.name | endswith($s)) | .name' | head -n 1)"
        DOWNLOAD_URL="$(echo "$RELEASE_JSON" | jq -r --arg s "$ASSET_SUFFIX" '(.assets // [])[] | select(.name | endswith($s)) | .url' | head -n 1)"
        CHECKSUMS_URL="$(echo "$RELEASE_JSON" | jq -r '(.assets // [])[] | select(.name == "checksums.txt") | .url' | head -n 1)"
    else
        # No jq available: use browser_download_url (works for public releases).
        DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep "${ASSET_SUFFIX}\"" | head -n 1 | cut -d '"' -f 4)"
        CHECKSUMS_URL="$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep '/checksums\.txt"' | head -n 1 | cut -d '"' -f 4)"
        [ -n "$DOWNLOAD_URL" ] && ARCHIVE_NAME="$(basename "$DOWNLOAD_URL")"
    fi
fi

# Fallback: direct download host (only possible with an explicit version,
# since we cannot resolve "latest"/"nightly" without the release metadata).
USED_FALLBACK="false"
if [ -z "$DOWNLOAD_URL" ]; then
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "nightly" ]; then
        echo "❌ Could not resolve a '$VERSION' release asset for $OS/$ARCH from GitHub."
        echo "   The release may not exist yet, or the token lacks access to ${REPO}."
        exit 1
    fi
    echo "GitHub asset not found; falling back to dotenv.cloud..."
    ARCHIVE_NAME="${PROJECT_NAME}_${VERSION#v}_${OS}_${ARCH}.${ARCHIVE_EXT}"
    DOWNLOAD_URL="https://dotenv.cloud/releases/cli/v${VERSION#v}/${ARCHIVE_NAME}"
    CHECKSUMS_URL="https://dotenv.cloud/releases/cli/v${VERSION#v}/checksums.txt"
    USED_FALLBACK="true"
fi

echo "Downloading: $ARCHIVE_NAME"
ARCHIVE_FILE="$(mktemp)"
gh_download "$DOWNLOAD_URL" "$ARCHIVE_FILE"
if [ ! -s "$ARCHIVE_FILE" ]; then
    echo "Download failed or file is empty"
    rm -f "$ARCHIVE_FILE"
    exit 1
fi

ARCHIVE_BASENAME="$ARCHIVE_NAME"

# --- Checksum verification (mandatory for GitHub releases) ---
verify_checksum() {
    local checksums_file="$1"
    local expected actual sha_tool

    # Exact filename match on the second field — avoids treating the archive
    # name as a regex and is robust to single/double-space separators.
    expected="$(awk -v f="$ARCHIVE_BASENAME" '$2 == f {print $1; exit}' "$checksums_file" 2>/dev/null)"
    if [ -z "$expected" ]; then
        echo "❌ No checksum entry found for ${ARCHIVE_BASENAME}"
        return 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        sha_tool="sha256sum"
        actual="$(sha256sum "$ARCHIVE_FILE" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
        sha_tool="shasum -a 256"
        actual="$(shasum -a 256 "$ARCHIVE_FILE" | awk '{print $1}')"
    else
        echo "❌ No SHA-256 tool available (sha256sum/shasum) — cannot verify download"
        return 1
    fi

    if [ "$expected" = "$actual" ]; then
        echo "✅ Checksum verification passed (via $sha_tool)"
        return 0
    fi
    echo "❌ Checksum verification failed!"
    echo "   Expected: $expected"
    echo "   Actual:   $actual"
    return 1
}

CHECKSUMS_FILE="$(mktemp)"
if [ -n "$CHECKSUMS_URL" ] && gh_download "$CHECKSUMS_URL" "$CHECKSUMS_FILE" 2>/dev/null && [ -s "$CHECKSUMS_FILE" ]; then
    if ! verify_checksum "$CHECKSUMS_FILE"; then
        rm -f "$ARCHIVE_FILE" "$CHECKSUMS_FILE"
        exit 1
    fi
else
    if [ "$USED_FALLBACK" = "true" ]; then
        echo "⚠️  Warning: checksums not available from fallback host — skipping verification"
    else
        echo "❌ checksums.txt not available for this release — refusing to install unverified binary"
        rm -f "$ARCHIVE_FILE" "$CHECKSUMS_FILE"
        exit 1
    fi
fi
rm -f "$CHECKSUMS_FILE"

# --- Extract the archive and locate the binary ---
EXTRACT_DIR="$(mktemp -d)"
if [ "$ARCHIVE_EXT" = "zip" ]; then
    if ! command -v unzip >/dev/null 2>&1; then
        echo "❌ 'unzip' is required to extract the Windows archive"
        rm -rf "$ARCHIVE_FILE" "$EXTRACT_DIR"
        exit 1
    fi
    unzip -q "$ARCHIVE_FILE" -d "$EXTRACT_DIR"
else
    tar -xzf "$ARCHIVE_FILE" -C "$EXTRACT_DIR"
fi
rm -f "$ARCHIVE_FILE"

BIN_PATH="$(find "$EXTRACT_DIR" -type f -name "${BINARY_NAME}${BIN_EXT}" | head -n 1)"
if [ -z "$BIN_PATH" ]; then
    echo "❌ Could not find '${BINARY_NAME}${BIN_EXT}' inside the archive"
    rm -rf "$EXTRACT_DIR"
    exit 1
fi

mv "$BIN_PATH" "$INSTALL_DIR/${BINARY_NAME}${BIN_EXT}"
chmod +x "$INSTALL_DIR/${BINARY_NAME}${BIN_EXT}"
rm -rf "$EXTRACT_DIR"

# Add to PATH for the current session
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
    echo "  - Binary location: $INSTALL_DIR/${BINARY_NAME}${BIN_EXT}"
    echo "  - Current PATH: $PATH"
    if [ -f "$INSTALL_DIR/${BINARY_NAME}${BIN_EXT}" ]; then
        echo ""
        echo "Binary exists at expected location. This is likely a PATH issue."
        ls -la "$INSTALL_DIR/${BINARY_NAME}${BIN_EXT}"
    else
        echo ""
        echo "ERROR: Binary not found at expected location!"
        exit 1
    fi
fi

# For GitHub Actions, ensure it's in PATH for subsequent steps
if [ -n "${GITHUB_PATH:-}" ]; then
    echo "$INSTALL_DIR" >> "$GITHUB_PATH"
fi
