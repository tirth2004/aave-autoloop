import { useState } from 'react'
import type { Position } from '../App'

interface CreatePositionModalProps {
  onClose: () => void
  onCreate: (params: Position['params']) => void
}

const CreatePositionModal = ({ onClose, onCreate }: CreatePositionModalProps) => {
  const [formData, setFormData] = useState({
    initialCollateralWeth: '0.01',
    loops: 2,
    borrowBps: 70,
    minHealthFactor: '1.3',
    minSwapOut: '0'
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onCreate(formData)
  }

  const handleChange = (field: string, value: string | number) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-dark-card border-2 border-primary-blue rounded-lg p-8 max-w-md w-full mx-4">
        <h2 className="text-2xl font-bold text-white mb-6">CREATE NEW POSITION</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Initial Collateral */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Initial Collateral (WETH)
            </label>
            <input
              type="number"
              step="0.01"
              value={formData.initialCollateralWeth}
              onChange={(e) => handleChange('initialCollateralWeth', e.target.value)}
              className="w-full bg-dark-bg border border-dark-border rounded px-4 py-2 text-white focus:outline-none focus:border-primary-blue"
              placeholder="0.01"
            />
            <p className="text-xs text-gray-500 mt-1">Initial Collateral (WETH) helper contract</p>
          </div>

          {/* Number of Loops */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Number of Loops
            </label>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => handleChange('loops', Math.max(1, formData.loops - 1))}
                className="bg-dark-bg border border-dark-border px-3 py-2 rounded text-white hover:border-primary-blue"
              >
                -
              </button>
              <input
                type="number"
                min="1"
                max="10"
                value={formData.loops}
                onChange={(e) => handleChange('loops', parseInt(e.target.value) || 1)}
                className="flex-1 bg-dark-bg border border-dark-border rounded px-4 py-2 text-white text-center focus:outline-none focus:border-primary-blue"
              />
              <button
                type="button"
                onClick={() => handleChange('loops', Math.min(10, formData.loops + 1))}
                className="bg-dark-bg border border-dark-border px-3 py-2 rounded text-white hover:border-primary-blue"
              >
                +
              </button>
            </div>
          </div>

          {/* Borrow Percentage */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Borrow Percentage: {formData.borrowBps}%
            </label>
            <input
              type="range"
              min="1"
              max="99"
              value={formData.borrowBps}
              onChange={(e) => handleChange('borrowBps', parseInt(e.target.value))}
              className="w-full accent-primary-blue"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>1%</span>
              <span>99%</span>
            </div>
          </div>

          {/* Minimum Health Factor */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Minimum Health Factor
            </label>
            <input
              type="number"
              step="0.1"
              min="1.0"
              value={formData.minHealthFactor}
              onChange={(e) => handleChange('minHealthFactor', e.target.value)}
              className="w-full bg-dark-bg border border-dark-border rounded px-4 py-2 text-white focus:outline-none focus:border-primary-blue"
              placeholder="1.3"
            />
          </div>

          {/* Min Swap Out */}
          <div>
            <label className="block text-sm text-gray-400 mb-2">
              Min Swap Out (Optional)
            </label>
            <input
              type="number"
              step="0.01"
              min="0"
              value={formData.minSwapOut}
              onChange={(e) => handleChange('minSwapOut', e.target.value)}
              className="w-full bg-dark-bg border border-dark-border rounded px-4 py-2 text-white focus:outline-none focus:border-primary-blue"
              placeholder="0"
            />
          </div>

          {/* Action Buttons */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 bg-dark-bg border border-dark-border hover:border-primary-blue px-4 py-2 rounded text-white font-medium transition-colors"
            >
              CANCEL
            </button>
            <button
              type="submit"
              className="flex-1 bg-primary-teal hover:bg-primary-blue px-4 py-2 rounded text-white font-medium transition-colors"
            >
              CREATE POSITION
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default CreatePositionModal
