#!/bin/bash

# Clone the repository into ./src/erc20Basic directory
REPO_URL="https://github.com/Ghonghito/levelupweb3"
SRC_DIR="./src"
REPO_DIR="$SRC_DIR/erc20Basic"
TEST_SCRIPT="./test/ERC20-Challenge.t.sol"

# Create the src directory if it doesn't exist
if [ ! -d "$SRC_DIR" ]; then
    mkdir "$SRC_DIR"
fi

# Clone the repository into ./src/erc20Basic if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Navigate to the contracts directory
cd "$REPO_DIR/contracts" || { echo "Contracts directory not found!"; exit 1; }

# Install Foundry if not already installed
if ! command -v forge &> /dev/null; then
    echo "Foundry is not installed. Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
fi

# Run the test script
echo "Running tests with Foundry..."
output=$(forge test --match-path "$TEST_SCRIPT" 2>&1)

# Check if at least one test succeeded
if echo "$output" | grep -q "Test result: ok"; then
    echo "At least one test succeeded!"
    exit 0
else
    echo "No tests succeeded."
    exit 1
fi
