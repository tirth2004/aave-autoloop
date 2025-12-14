import { useState } from 'react'

const Header = () => {
  const [isConnected, setIsConnected] = useState(false)
  const [walletAddress, setWalletAddress] = useState<string>('')

  const handleConnectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({ 
          method: 'eth_requestAccounts' 
        })
        setWalletAddress(accounts[0])
        setIsConnected(true)
      } catch (error) {
        console.error('Error connecting wallet:', error)
      }
    } else {
      alert('Please install MetaMask!')
    }
  }

  return (
    <header className="bg-dark-card border-b border-dark-border">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        {/* Logo and Title */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary-teal flex items-center justify-center">
            <span className="text-white font-bold text-xl">E</span>
          </div>
          <h1 className="text-2xl font-bold text-white">AutoLooper Reactive</h1>
        </div>

        {/* Network and Wallet */}
        <div className="flex items-center gap-4">
          {/* Network Badge */}
          <div className="flex items-center gap-2 bg-primary-blue px-4 py-2 rounded-full">
            <div className="w-4 h-4 rounded-full bg-white"></div>
            <span className="text-white font-medium">Sepolia Network</span>
          </div>

          {/* Connect Wallet Button */}
          <button
            onClick={handleConnectWallet}
            className="bg-primary-blue hover:bg-primary-teal px-6 py-2 rounded-full text-white font-medium transition-colors"
          >
            {isConnected 
              ? `${walletAddress.slice(0, 6)}...${walletAddress.slice(-4)}`
              : 'Connect Wallet'
            }
          </button>
        </div>
      </div>
    </header>
  )
}

export default Header
