import React from 'react'
import { Inbox } from 'lucide-react'

interface EmptyStateProps {
  message?: string
  icon?: React.ReactNode
}

export function EmptyState({ message = 'No data found', icon }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 gap-4 text-center">
      <div className="text-gray-600">
        {icon ?? <Inbox className="h-16 w-16" />}
      </div>
      <p className="text-gray-400 text-sm">{message}</p>
    </div>
  )
}

export default EmptyState
