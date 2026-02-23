import React, { useState } from 'react'
import { ChevronUp, ChevronDown } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'
import EmptyState from './EmptyState'
import Pagination from './Pagination'

export interface Column<T = Record<string, unknown>> {
  key: string
  label: string
  sortable?: boolean
  render?: (value: unknown, row: T) => React.ReactNode
  className?: string
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  isLoading?: boolean
  total?: number
  page?: number
  limit?: number
  onPageChange?: (page: number) => void
  onSort?: (key: string, order: 'asc' | 'desc') => void
  rowKey?: (row: T) => string
  emptyMessage?: string
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function DataTable<T = any>({
  columns,
  data,
  isLoading,
  total = 0,
  page = 1,
  limit = 20,
  onPageChange,
  onSort,
  rowKey,
  emptyMessage,
}: DataTableProps<T>) {
  const [sortKey, setSortKey] = useState<string>('')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc')

  const handleSort = (key: string) => {
    const newOrder = sortKey === key && sortOrder === 'asc' ? 'desc' : 'asc'
    setSortKey(key)
    setSortOrder(newOrder)
    onSort?.(key, newOrder)
  }

  if (isLoading) {
    return (
      <div className="flex justify-center items-center py-20">
        <LoadingSpinner />
      </div>
    )
  }

  if (!data.length) {
    return <EmptyState message={emptyMessage} />
  }

  return (
    <div className="space-y-4">
      <div className="overflow-x-auto rounded-lg border border-surface">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-surface bg-card">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={`px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-400 ${col.sortable ? 'cursor-pointer select-none hover:text-primary' : ''} ${col.className ?? ''}`}
                  onClick={() => col.sortable && handleSort(col.key)}
                >
                  <div className="flex items-center gap-1">
                    {col.label}
                    {col.sortable && sortKey === col.key && (
                      sortOrder === 'asc' ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-surface">
            {data.map((row, idx) => (
              <tr
                key={rowKey ? rowKey(row) : idx}
                className="hover:bg-surface/50 transition-colors"
              >
                {columns.map((col) => (
                  <td key={col.key} className={`px-4 py-3 text-gray-300 ${col.className ?? ''}`}>
                    {col.render ? col.render((row as Record<string, unknown>)[col.key], row) : String((row as Record<string, unknown>)[col.key] ?? '')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {total > limit && onPageChange && (
        <Pagination page={page} total={total} limit={limit} onPageChange={onPageChange} />
      )}
    </div>
  )
}

export default DataTable
