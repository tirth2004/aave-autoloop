import { useState } from 'react'
import Header from './components/Header'
import PositionCard from './components/PositionCard'
import CreatePositionModal from './components/CreatePositionModal'

export interface Position {
  id: string
  name: string
  status: 'active' | 'inactive' | 'pending'
  params: {
    initialCollateralWeth: string
    loops: number
    borrowBps: number
    minHealthFactor: string
    minSwapOut: string
  }
  current?: {
    healthFactor: string
    collateral: string
    debt: string
    leverage: string
  }
  createdAt: string
}

function App() {
  const [positions, setPositions] = useState<Position[]>([
    {
      id: '1',
      name: 'Position #1',
      status: 'active',
      params: {
        initialCollateralWeth: '0.01',
        loops: 2,
        borrowBps: 70,
        minHealthFactor: '1.3',
        minSwapOut: '0'
      },
      current: {
        healthFactor: '1.45',
        collateral: '2.5',
        debt: '1,500',
        leverage: '3.2x'
      },
      createdAt: new Date().toISOString()
    },
    {
      id: '2',
      name: 'Position #2',
      status: 'inactive',
      params: {
        initialCollateralWeth: '0.05',
        loops: 3,
        borrowBps: 60,
        minHealthFactor: '1.4',
        minSwapOut: '0'
      },
      createdAt: new Date().toISOString()
    },
    {
      id: '3',
      name: 'Position #3',
      status: 'inactive',
      params: {
        initialCollateralWeth: '0.01',
        loops: 2,
        borrowBps: 70,
        minHealthFactor: '1.3',
        minSwapOut: '0'
      },
      current: {
        healthFactor: '1.45',
        collateral: '2.5',
        debt: '1,500',
        leverage: '3.2x'
      },
      createdAt: new Date().toISOString()
    }
  ])

  const [isModalOpen, setIsModalOpen] = useState(false)

  const handleCreatePosition = (params: Position['params']) => {
    const newPosition: Position = {
      id: String(positions.length + 1),
      name: `Position #${positions.length + 1}`,
      status: 'pending',
      params,
      createdAt: new Date().toISOString()
    }
    setPositions([...positions, newPosition])
    setIsModalOpen(false)
  }

  const handleClosePosition = (id: string) => {
    setPositions(positions.map(p => 
      p.id === id ? { ...p, status: 'inactive' as const } : p
    ))
  }

  const handleDeletePosition = (id: string) => {
    setPositions(positions.filter(p => p.id !== id))
  }

  return (
    <div className="min-h-screen bg-dark-bg">
      <Header />
      
      <main className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {positions.map((position) => (
            <PositionCard
              key={position.id}
              position={position}
              onClose={() => handleClosePosition(position.id)}
              onDelete={() => handleDeletePosition(position.id)}
            />
          ))}
          
          {/* Add Position Card */}
          <div 
            className="border-2 border-dashed border-primary-blue rounded-lg p-6 flex items-center justify-center cursor-pointer hover:border-primary-teal transition-colors"
            onClick={() => setIsModalOpen(true)}
          >
            <div className="text-center">
              <div className="text-4xl mb-2">+</div>
              <div className="text-primary-blue font-semibold">ADD POSITION</div>
            </div>
          </div>
        </div>
      </main>

      {isModalOpen && (
        <CreatePositionModal
          onClose={() => setIsModalOpen(false)}
          onCreate={handleCreatePosition}
        />
      )}
    </div>
  )
}

export default App
