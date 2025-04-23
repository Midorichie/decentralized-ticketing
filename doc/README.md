# Decentralized Customer Support Ticketing System

A blockchain-based customer support ticketing system built on Stacks blockchain using Clarity smart contracts.

## Project Overview

This project implements a decentralized customer support system where:
- Users can create support tickets stored on the blockchain
- Support staff can respond to and update ticket status
- All interactions are transparent and immutable
- Ownership of tickets is verifiable

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli) - For deployment and interaction
- Node.js and NPM (for frontend development if needed)

## Setup Instructions

1. Clone this repository:
```bash
git clone [repository-url]
cd decentralized-ticketing
```

2. Install Clarinet if you haven't already:
```bash
curl -sSL https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar -xz
chmod +x ./clarinet
sudo mv ./clarinet /usr/local/bin/
```

3. Initialize the Clarinet project:
```bash
clarinet new
```

4. Run Clarinet console to interact with the contracts:
```bash
clarinet console
```

## Project Structure

```
decentralized-ticketing/
├── Clarinet.toml           # Project configuration
├── contracts/
│   └── ticket-system.clar  # Main smart contract
├── tests/
│   └── ticket-system_test.ts  # Contract tests
└── README.md
```

## Smart Contract Functions

### Ticket System Contract

- `create-ticket`: Create a new support ticket
- `update-ticket-status`: Change the status of a ticket
- `add-comment`: Add a comment to an existing ticket
- `get-ticket`: Retrieve ticket information
- `get-tickets-by-owner`: List all tickets owned by an address

## Development Workflow

1. Make changes to the Clarity contracts in the `contracts/` directory
2. Test your changes using the test suite: `clarinet test`
3. Deploy to testnet when ready: `clarinet deploy --testnet`

## Security Considerations

- All functions implement proper authorization checks
- Tickets are associated with their creator's address
- Staff roles are managed through a secure principal-based system
