#!/bin/bash
# ==============================================================================
# Fizzlebee's Treasure Tracker - Interactive Release Helper
# Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
# Licensed under the BSD 3-Clause License (see LICENSE file)
# ==============================================================================
# This script provides an interactive release workflow:
# 1. Reads current version from TOC file
# 2. Asks user: patch / minor / major?
# 3. Calculates next version number
# 4. Updates TOC file
# 5. Creates git commit and tag
# 6. Pushes to GitHub (triggers automated release)
# ==============================================================================

set -e  # Exit on error

# ==============================================================================
# CONFIGURATION
# ==============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="FizzlebeesTreasureTracker"
TOC_FILE="$PROJECT_ROOT/$PROJECT_NAME.toc"

# ==============================================================================
# COLOUR CODES
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Colour

# ==============================================================================
# FUNCTIONS
# ==============================================================================

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC}   $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Extract current version from TOC file
get_current_version() {
    if [ ! -f "$TOC_FILE" ]; then
        print_error "TOC file not found: $TOC_FILE"
        exit 1
    fi

    # Extract version line: ## Version: 1.0.0
    local version=$(grep "^## Version:" "$TOC_FILE" | sed 's/^## Version: //' | tr -d '\r')

    if [ -z "$version" ]; then
        print_error "Could not extract version from TOC file"
        exit 1
    fi

    echo "$version"
}

# Calculate next version based on release type
calculate_next_version() {
    local current=$1
    local release_type=$2

    # Split version into parts (MAJOR.MINOR.PATCH)
    IFS='.' read -r major minor patch <<< "$current"

    case $release_type in
        patch)
            patch=$((patch + 1))
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        *)
            print_error "Invalid release type: $release_type"
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Update TOC file with new version
update_toc_version() {
    local new_version=$1
    local current_date=$(date +%Y-%m-%d)

    print_info "Updating TOC file: $TOC_FILE"

    # Update version line
    sed -i.bak "s/^## Version:.*/## Version: $new_version/" "$TOC_FILE"

    # Update date line
    sed -i.bak "s/^## X-Date:.*/## X-Date: $current_date/" "$TOC_FILE"

    # Remove backup file
    rm -f "$TOC_FILE.bak"

    print_success "TOC file updated to version $new_version"
}

# Create git commit and tag
create_release() {
    local version=$1

    print_info "Creating git commit..."
    git add "$TOC_FILE"
    git commit -m "chore: bump version to $version"

    print_info "Creating git tag v$version..."
    git tag "v$version"

    print_success "Git commit and tag created"
}

# Push to GitHub
push_release() {
    local version=$1

    print_info "Pushing to GitHub..."
    git push
    git push --tags

    print_success "Pushed to GitHub"
    print_success "GitHub Actions will now build and create the release automatically"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

echo ""
echo -e "${YELLOW}================================================================================${NC}"
echo -e "${YELLOW} Fizzlebee's Treasure Tracker - Interactive Release Helper${NC}"
echo -e "${YELLOW}================================================================================${NC}"
echo ""

# Verify we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    print_error "Not a git repository: $PROJECT_ROOT"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(get_current_version)
print_info "Current version: $CURRENT_VERSION"
echo ""

# Ask for release type
echo -e "${CYAN}What type of release would you like to create?${NC}"
echo ""
echo "  ${GREEN}patch${NC}  - Bug fixes, small changes        ($CURRENT_VERSION → $(calculate_next_version $CURRENT_VERSION patch))"
echo "  ${GREEN}minor${NC}  - New features, backwards compatible ($CURRENT_VERSION → $(calculate_next_version $CURRENT_VERSION minor))"
echo "  ${GREEN}major${NC}  - Breaking changes               ($CURRENT_VERSION → $(calculate_next_version $CURRENT_VERSION major))"
echo ""
read -p "Release type [patch/minor/major]: " RELEASE_TYPE

# Validate input
case $RELEASE_TYPE in
    patch|minor|major)
        ;;
    *)
        print_error "Invalid release type. Please choose: patch, minor, or major"
        exit 1
        ;;
esac

# Calculate next version
NEXT_VERSION=$(calculate_next_version $CURRENT_VERSION $RELEASE_TYPE)

echo ""
print_info "Version bump: $CURRENT_VERSION → $NEXT_VERSION"
echo ""

# Confirm
read -p "$(echo -e ${CYAN}Create release v$NEXT_VERSION? [y/N]:${NC} )" CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    print_warning "Release cancelled"
    exit 0
fi

echo ""

# Update TOC file
update_toc_version $NEXT_VERSION

# Create git commit and tag
create_release $NEXT_VERSION

# Push to GitHub
push_release $NEXT_VERSION

# Success
echo ""
echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN} Release v$NEXT_VERSION created successfully!${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""
print_success "GitHub Actions is now building the release"
print_info "Monitor progress: https://github.com/Fizzlebees-Rocket-Shop/$PROJECT_NAME/actions"
print_info "Release will be available at: https://github.com/Fizzlebees-Rocket-Shop/$PROJECT_NAME/releases/tag/v$NEXT_VERSION"
echo ""
