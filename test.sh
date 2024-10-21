#!/bin/bash

# Clone the repository into ./src/erc20Basic directory
REPO_URL="https://github.com/Ghonghito/levelupweb3"
SRC_DIR="./src"
REPO_DIR="$SRC_DIR/erc20Basic"
SAVE_DIR="$SRC_DIR/save"
TEST_TEMPLATE="./test/save-ERC20-Challenge.txt"
TEST_FILE="./test/ERC20-Challenge.t.sol"

# Create the src directory if it doesn't exist
if [ ! -d "$SRC_DIR" ]; then
    mkdir "$SRC_DIR"
fi

# Clone the repository into ./src/erc20Basic if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Create the save directory if it doesn't exist
if [ ! -d "$SAVE_DIR" ]; then
    mkdir "$SAVE_DIR"
fi

# Copy the cloned repository to ./src/save (including .git)
rsync -av "$REPO_DIR/" "$SAVE_DIR/"

# Navigate to the cloned directory
cd "$REPO_DIR" || { echo "Repository directory not found!"; exit 1; }

# Collect all .sol files from both the root and contracts folder
sol_files=$(find . -maxdepth 1 -name "*.sol")
if [ -d "contracts" ]; then
    echo "Contracts directory found. Including files from contracts..."
    contract_files=$(find contracts -maxdepth 1 -name "*.sol")
    sol_files="$sol_files $contract_files"
else
    echo "Contracts directory not found."
fi

# Check if any .sol files were found
if [ -z "$sol_files" ]; then
    echo "No Solidity (.sol) files found!"
    exit 1
else
    echo "Solidity files to be tested:"
    echo "$sol_files"
fi

# Install Foundry if not already installed
if ! command -v forge &> /dev/null; then
    echo "Foundry is not installed. Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
fi

# Function to replace contract name with MyToken
replace_contract_name() {
    local file_path="$1"
    # Find contract name with regex and replace it with 'MyToken'
    contract_name=$(grep -Po '(?<=contract\s)(\w+)' "$file_path")
    if [ -z "$contract_name" ]; then
        echo "No contract found in $file_path"
        return 1
    fi
    echo "Replacing contract $contract_name with MyToken in $file_path"
    sed -i "s/contract $contract_name/contract MyToken/g" "$file_path"
}

# Run the tests for each .sol file
any_test_succeeded=false
for sol_file in $sol_files; do
    echo "Running tests for $sol_file..."

    # Replace contract name by `MyToken` in the source file
    replace_contract_name "$sol_file" || continue

    # Prepare the test file by copying the template and replacing placeholders
    cp "../../$TEST_TEMPLATE" "../../$TEST_FILE"

    # Get the relative path between src and the file to test
    replacement_string=$(realpath --relative-to="../../$TEST_FILE" "$sol_file")
    echo "Replacing __TO_BE_REPLACED__ with $replacement_string in $TEST_FILE"

    # Use sed with the variable
    sed -i.bak "s|__TO_BE_REPLACED__|$replacement_string|g" "../../$TEST_FILE"

    # Run the test and display the output live
    echo "Running forge test for $sol_file..."
    cd ../../

    if forge test --match-path "$TEST_FILE"; then
        any_test_succeeded=true
        echo "Test succeeded for $sol_file"
    else
        echo "Test failed for $sol_file"
    fi

    cd src/erc20Basic/

    # Clean up: Remove the test file after the test
    rm -f "$TEST_FILE" "$TEST_FILE.bak"

    # Remove src/erc20Basic and restore it from src/save (including .git)
    echo "Removing src/erc20Basic and restoring it from src/save..."
    rm -rf "$REPO_DIR"

    if any_test_succeeded; then
        break
    fi
done

# Clean
echo "Cleaning up ..."
cd ../../
rm -f "$TEST_FILE"
rm -f "$TEST_FILE.bak"
rm -rf "$REPO_DIR"
rm -rf "$SAVE_DIR"
forge clean

# Final check if any test succeeded
if [ "$any_test_succeeded" = true ]; then
    echo "At least one test succeeded!"
    exit 0
else
    echo "No tests succeeded."
    exit 1
fi
