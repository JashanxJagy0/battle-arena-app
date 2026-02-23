import React from 'react'
import { LucideIcon } from 'lucide-react'
import { TrendingUp, TrendingDown } from 'lucide-react'

interface StatCardProps {
  title: string
  value: string | number
  change?: number
  icon: LucideIcon
  color?: 'primary' | 'secondary' | 'accent' | 'danger'
  prefix?: string
  suffix?: string
}

const colorMap = {
  primary: { bg: 'bg-primary/10', text: 'text-primary', border: 'border-primary/20', shadow: 'shadow-neon' },
  secondary: { bg: 'bg-secondary/10', text: 'text-secondary', border: 'border-secondary/20', shadow: 'shadow-neon-green' },
  accent: { bg: 'bg-accent/10', text: 'text-accent', border: 'border-accent/20', shadow: 'shadow-neon-purple' },
  danger: { bg: 'bg-danger/10', text: 'text-danger', border: 'border-danger/20', shadow: 'shadow-neon-danger' },
}

export function StatCard({ title, value, change, icon: Icon, color = 'primary', prefix, suffix }: StatCardProps) {
  const colors = colorMap[color]
  const isPositive = (change ?? 0) >= 0

  return (
    <div className={`bg-card border ${colors.border} rounded-xl p-5 hover:${colors.shadow} transition-all duration-300`}>
      <div className="flex items-start justify-between">
        <div className="space-y-1 flex-1">
          <p className="text-sm text-gray-400">{title}</p>
          <p className={`text-2xl font-bold ${colors.text}`}>
            {prefix}{typeof value === 'number' ? value.toLocaleString() : value}{suffix}
          </p>
        </div>
        <div className={`${colors.bg} p-3 rounded-lg`}>
          <Icon className={`h-6 w-6 ${colors.text}`} />
        </div>
      </div>
      {change !== undefined && (
        <div className={`flex items-center gap-1 mt-3 text-sm ${isPositive ? 'text-secondary' : 'text-danger'}`}>
          {isPositive ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
          <span>{Math.abs(change)}% from last period</span>
        </div>
      )}
    </div>
  )
}

export default StatCard
