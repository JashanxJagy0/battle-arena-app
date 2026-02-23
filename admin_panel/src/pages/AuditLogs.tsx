import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ChevronDown, ChevronRight } from 'lucide-react'
import SearchInput from '../components/SearchInput'
import DateRangePicker from '../components/DateRangePicker'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Pagination from '../components/Pagination'
import { auditService, AuditLog } from '../services/audit.service'
import { usePagination } from '../hooks/usePagination'

function AuditRow({ log }: { log: AuditLog }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <div className="border-b border-surface last:border-0">
      <div
        className="flex items-center gap-4 px-4 py-3 hover:bg-surface/50 cursor-pointer transition-colors"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="text-gray-400">
          {expanded ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
        </div>
        <div className="flex-1 grid grid-cols-5 gap-4 text-sm">
          <span className="text-white font-medium">{log.adminName}</span>
          <span className="text-primary font-mono text-xs">{log.action}</span>
          <span className="text-gray-400 capitalize">{log.resource}</span>
          <span className="text-gray-500 font-mono text-xs">{log.resourceId?.slice(0, 8) ?? '—'}</span>
          <span className="text-gray-400 text-xs">{new Date(log.createdAt).toLocaleString()}</span>
        </div>
      </div>
      {expanded && log.details && (
        <div className="px-12 pb-4">
          <pre className="text-xs text-gray-400 bg-background rounded-lg p-4 overflow-x-auto">
            {JSON.stringify(log.details, null, 2)}
          </pre>
        </div>
      )}
    </div>
  )
}

export function AuditLogs() {
  const pagination = usePagination(30)
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [action, setAction] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['audit-logs', pagination.page, action, startDate, endDate],
    queryFn: () => auditService.getAuditLogs({
      page: pagination.page,
      limit: pagination.limit,
      action: action || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
    placeholderData: { logs: [], total: 0, page: 1, limit: 30 },
  })

  return (
    <div className="space-y-5">
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3">
        <SearchInput onSearch={setAction} placeholder="Filter by action..." className="flex-1 min-w-[200px]" />
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
      </div>

      <div className="bg-card border border-surface rounded-xl overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-5 gap-4 px-12 py-3 bg-surface/30 border-b border-surface text-xs font-semibold uppercase tracking-wider text-gray-400">
          <span>Admin</span>
          <span>Action</span>
          <span>Resource</span>
          <span>Resource ID</span>
          <span>Timestamp</span>
        </div>

        {isLoading ? (
          <div className="flex justify-center py-12"><LoadingSpinner /></div>
        ) : !data?.logs.length ? (
          <EmptyState message="No audit logs found" />
        ) : (
          <div>
            {data.logs.map((log) => <AuditRow key={log.id} log={log} />)}
          </div>
        )}
      </div>

      {(data?.total ?? 0) > pagination.limit && (
        <Pagination page={pagination.page} total={data?.total ?? 0} limit={pagination.limit} onPageChange={pagination.setPage} />
      )}
    </div>
  )
}

export default AuditLogs
