
This is a simple script used to verify if a user's erc20 implementation is correct.

It will:
- Clone the repository
- get all contracts from `./` and `./contracts` directories
- test them using the `save-ERC20-Challenge.txt`
- if at least one succeeds, we will consider the implementation correct
- saves the results in `./output.csv`: `repository, result`

## Usage

Make the script executable:
```bash
sudo chmod +x test.sh
```

Run the script:
```bash
./test.sh
```