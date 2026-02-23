import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Download } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import SearchInput from '../components/SearchInput'
import DateRangePicker from '../components/DateRangePicker'
import { transactionService, Transaction } from '../services/transaction.service'
import { usePagination } from '../hooks/usePagination'

export function WalletManagement() {
  const pagination = usePagination(20)
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['transactions', pagination.page, search, typeFilter, statusFilter, startDate, endDate],
    queryFn: () => transactionService.getTransactions({
      page: pagination.page,
      limit: pagination.limit,
      search: search || undefined,
      type: typeFilter || undefined,
      status: statusFilter || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
    placeholderData: { transactions: [], total: 0, page: 1, limit: 20 },
  })

  const handleExport = async () => {
    try {
      const blob = await transactionService.exportTransactions({ search: search || undefined, type: typeFilter || undefined, status: statusFilter || undefined, startDate: startDate || undefined, endDate: endDate || undefined })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `transactions-${new Date().toISOString().split('T')[0]}.csv`
      a.click()
      URL.revokeObjectURL(url)
      toast.success('Exported successfully!')
    } catch {
      toast.error('Export failed')
    }
  }

  const columns: Column<Transaction>[] = [
    { key: 'id', label: 'ID', render: (v) => <span className="font-mono text-xs text-gray-400">{String(v).slice(0, 8)}...</span> },
    { key: 'username', label: 'User', render: (v) => <span className="text-white font-medium">{String(v)}</span> },
    {
      key: 'type', label: 'Type',
      render: (v) => {
        const colors: Record<string, string> = { deposit: 'text-secondary', withdrawal: 'text-danger', prize: 'text-primary', bonus: 'text-accent', entry_fee: 'text-yellow-400', refund: 'text-gray-300', admin_credit: 'text-secondary', admin_debit: 'text-danger' }
        return <span className={`text-xs font-medium ${colors[String(v)] ?? 'text-gray-400'}`}>{String(v).replace('_', ' ')}</span>
      },
    },
    {
      key: 'amount', label: 'Amount', sortable: true,
      render: (v, row) => {
        const isDebit = ['withdrawal', 'entry_fee', 'admin_debit'].includes(String(row.type))
        return <span className={`font-semibold ${isDebit ? 'text-danger' : 'text-secondary'}`}>{isDebit ? '-' : '+'}₹{Number(v).toLocaleString()}</span>
      },
    },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'reference', label: 'Reference', render: (v) => <span className="text-gray-400 text-xs font-mono">{String(v ?? '—')}</span> },
    { key: 'createdAt', label: 'Date', render: (v) => <span className="text-gray-400 text-xs">{new Date(String(v)).toLocaleString()}</span> },
  ]

  return (
    <div className="space-y-5">
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3 items-center justify-between">
        <div className="flex flex-wrap gap-3 flex-1">
          <SearchInput onSearch={setSearch} placeholder="Search transactions..." className="flex-1 min-w-[200px]" />
          <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
            <option value="">All Types</option>
            <option value="deposit">Deposit</option>
            <option value="withdrawal">Withdrawal</option>
            <option value="entry_fee">Entry Fee</option>
            <option value="prize">Prize</option>
            <option value="bonus">Bonus</option>
            <option value="refund">Refund</option>
            <option value="admin_credit">Admin Credit</option>
            <option value="admin_debit">Admin Debit</option>
          </select>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
        </div>
        <button onClick={handleExport} className="flex items-center gap-2 px-4 py-2 bg-secondary text-black rounded-lg font-medium hover:bg-secondary/80 transition-colors">
          <Download className="h-4 w-4" /> Export CSV
        </button>
      </div>

      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data?.transactions ?? []}
          isLoading={isLoading}
          total={data?.total ?? 0}
          page={pagination.page}
          limit={pagination.limit}
          onPageChange={pagination.setPage}
          rowKey={(row) => row.id}
          emptyMessage="No transactions found"
        />
      </div>
    </div>
  )
}

export default WalletManagement
