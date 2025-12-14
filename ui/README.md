# AutoLooper Reactive UI

React + TypeScript + Vite UI for managing AutoLooper reactive positions.

## Tech Stack

- **Vite** - Build tool
- **React 19** - UI framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Ethers.js** - Web3 interactions

## Getting Started

### Install Dependencies
```bash
npm install
```

### Run Development Server
```bash
npm run dev
```

### Build for Production
```bash
npm run build
```

## Project Structure

```
src/
├── components/
│   ├── Header.tsx           # Top header with logo, network, wallet
│   ├── PositionCard.tsx      # Individual position card component
│   └── CreatePositionModal.tsx # Modal for creating new positions
├── App.tsx                   # Main app component
├── main.tsx                  # Entry point
└── index.css                 # Global styles with Tailwind
```

## Features

- View all positions in a grid layout
- See position status (Active/Inactive)
- Display position parameters and current stats
- Create new positions via modal form
- Connect wallet functionality
- Close/Delete positions

## Environment Variables

Create a `.env` file for configuration:
```
VITE_RPC_URL=your_rpc_url
VITE_CONTRACT_ADDRESS=your_contract_address
```

## Next Steps

- [ ] Integrate with smart contracts
- [ ] Add real-time data fetching
- [ ] Implement transaction handling
- [ ] Add error handling and loading states
- [ ] Connect to Reactive Network
