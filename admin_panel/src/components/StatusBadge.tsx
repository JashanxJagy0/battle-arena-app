import React from 'react'

type Status =
  | 'active' | 'inactive' | 'banned' | 'suspended'
  | 'pending' | 'completed' | 'failed' | 'cancelled'
  | 'open' | 'closed' | 'resolved' | 'rejected' | 'investigating'
  | 'ongoing' | 'draft' | 'waiting' | 'disputed'
  | 'approved' | 'win' | 'loss'
  | string

const statusStyles: Record<string, string> = {
  active: 'bg-secondary/20 text-secondary border-secondary/30',
  approved: 'bg-secondary/20 text-secondary border-secondary/30',
  completed: 'bg-secondary/20 text-secondary border-secondary/30',
  win: 'bg-secondary/20 text-secondary border-secondary/30',
  resolved: 'bg-secondary/20 text-secondary border-secondary/30',

  pending: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  waiting: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  investigating: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  ongoing: 'bg-primary/20 text-primary border-primary/30',
  open: 'bg-primary/20 text-primary border-primary/30',
  draft: 'bg-gray-500/20 text-gray-400 border-gray-500/30',

  banned: 'bg-danger/20 text-danger border-danger/30',
  rejected: 'bg-danger/20 text-danger border-danger/30',
  failed: 'bg-danger/20 text-danger border-danger/30',
  cancelled: 'bg-danger/20 text-danger border-danger/30',
  disputed: 'bg-danger/20 text-danger border-danger/30',
  loss: 'bg-danger/20 text-danger border-danger/30',

  suspended: 'bg-accent/20 text-accent border-accent/30',
  inactive: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
  closed: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
}

interface StatusBadgeProps {
  status: Status
  className?: string
}

export function StatusBadge({ status, className = '' }: StatusBadgeProps) {
  const style = statusStyles[status.toLowerCase()] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30'
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${style} ${className}`}>
      {status}
    </span>
  )
}

export default StatusBadge
