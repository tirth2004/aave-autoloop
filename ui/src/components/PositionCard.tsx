import type { Position } from '../App'

interface PositionCardProps {
  position: Position
  onClose: () => void
  onDelete: () => void
}

const PositionCard = ({ position, onClose, onDelete }: PositionCardProps) => {
  const isActive = position.status === 'active'
  const isInactive = position.status === 'inactive'

  return (
    <div className="bg-dark-card border-2 border-primary-blue rounded-lg p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-xl font-semibold text-white">{position.name}</h3>
        <div className={`px-3 py-1 rounded-full flex items-center gap-2 ${
          isActive 
            ? 'bg-green-500/20 text-green-400 border border-green-500'
            : 'bg-red-500/20 text-red-400 border border-red-500'
        }`}>
          <div className={`w-2 h-2 rounded-full ${
            isActive ? 'bg-green-400' : 'bg-red-400'
          }`}></div>
          <span className="text-sm font-medium">
            {isActive ? 'ACTIVE' : 'INACTIVE'}
          </span>
        </div>
      </div>

      {/* Initial Parameters */}
      <div className="space-y-2 mb-4">
        <div className="text-sm text-gray-400">
          Initial Collateral: <span className="text-white">{position.params.initialCollateralWeth} WETH</span>
        </div>
        <div className="text-sm text-gray-400">
          Loops: <span className="text-white">{position.params.loops}</span>
        </div>
        <div className="text-sm text-gray-400">
          Borrow %: <span className="text-white">{position.params.borrowBps}%</span>
        </div>
        <div className="text-sm text-gray-400">
          Min Health Factor: <span className="text-white">{position.params.minHealthFactor}</span>
        </div>
        <div className="text-sm text-gray-400">
          Min Swap Out: <span className="text-white">{position.params.minSwapOut}</span>
        </div>
      </div>

      {/* Current Status */}
      {isActive && position.current ? (
        <div className="border-t border-dark-border pt-4 mb-4 space-y-2">
          <div className="text-sm text-gray-400">
            Health Factor: <span className="text-green-400 font-semibold">{position.current.healthFactor}</span>
            <span className="ml-2 w-2 h-2 rounded-full bg-green-400 inline-block"></span>
          </div>
          <div className="text-sm text-gray-400">
            Current Collateral: <span className="text-white">{position.current.collateral} WETH</span>
          </div>
          <div className="text-sm text-gray-400">
            Current Debt: <span className="text-white">{position.current.debt} USDC</span>
          </div>
          <div className="text-sm text-gray-400">
            Leverage: <span className="text-white">{position.current.leverage}</span>
          </div>
        </div>
      ) : (
        <div className="border-t border-dark-border pt-4 mb-4">
          <div className="text-sm text-gray-400">
            {isInactive ? 'No active position' : 'Position pending...'}
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex gap-2">
        <button className="flex-1 bg-primary-blue hover:bg-primary-teal px-4 py-2 rounded text-white font-medium transition-colors">
          VIEW DETAILS
        </button>
        {isActive ? (
          <button 
            onClick={onClose}
            className="flex-1 bg-red-500 hover:bg-red-600 px-4 py-2 rounded text-white font-medium transition-colors"
          >
            CLOSE POSITION
          </button>
        ) : (
          <button 
            onClick={onDelete}
            className="flex-1 bg-red-500 hover:bg-red-600 px-4 py-2 rounded text-white font-medium transition-colors"
          >
            DELETE
          </button>
        )}
      </div>
    </div>
  )
}

export default PositionCard
