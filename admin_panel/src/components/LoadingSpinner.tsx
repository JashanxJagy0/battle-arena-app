import React from 'react'

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg'
}

const sizeMap = { sm: 'h-5 w-5', md: 'h-8 w-8', lg: 'h-12 w-12' }

export function LoadingSpinner({ size = 'md' }: LoadingSpinnerProps) {
  return (
    <div
      className={`${sizeMap[size]} animate-spin rounded-full border-2 border-surface`}
      style={{ borderTopColor: '#00D4FF' }}
    />
  )
}

export default LoadingSpinner
