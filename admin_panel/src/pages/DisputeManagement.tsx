import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Eye } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import SearchInput from '../components/SearchInput'
import DateRangePicker from '../components/DateRangePicker'
import { disputeService, Dispute } from '../services/dispute.service'
import { usePagination } from '../hooks/usePagination'

export function DisputeManagement() {
  const qc = useQueryClient()
  const pagination = usePagination(20)
  const [statusFilter, setStatusFilter] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [search, setSearch] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [selectedDispute, setSelectedDispute] = useState<Dispute | null>(null)
  const [viewModal, setViewModal] = useState(false)
  const [resolution, setResolution] = useState('')
  const [outcome, setOutcome] = useState<'resolved' | 'rejected'>('resolved')

  const { data, isLoading } = useQuery({
    queryKey: ['disputes', pagination.page, search, statusFilter, typeFilter, startDate, endDate],
    queryFn: () => disputeService.getDisputes({
      page: pagination.page,
      limit: pagination.limit,
      status: statusFilter || undefined,
      type: typeFilter || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
    placeholderData: { disputes: [], total: 0, page: 1, limit: 20 },
  })

  const resolveMutation = useMutation({
    mutationFn: ({ id, resolution, outcome }: { id: string; resolution: string; outcome: 'resolved' | 'rejected' }) =>
      disputeService.resolveDispute(id, resolution, outcome),
    onSuccess: () => {
      toast.success('Dispute resolved!')
      qc.invalidateQueries({ queryKey: ['disputes'] })
      setViewModal(false)
      setResolution('')
    },
    onError: () => toast.error('Failed to resolve dispute'),
  })

  const columns: Column<Dispute>[] = [
    { key: 'id', label: 'ID', render: (v) => <span className="font-mono text-xs text-gray-400">{String(v).slice(0, 8)}...</span> },
    { key: 'type', label: 'Type', render: (v) => <span className="capitalize text-gray-300">{String(v)}</span> },
    { key: 'reason', label: 'Reason', render: (v) => <span className="text-white max-w-[200px] truncate block">{String(v)}</span> },
    {
      key: 'reportedBy', label: 'Reported By',
      render: (v) => {
        const user = v as Dispute['reportedBy']
        return <span className="text-primary">{user?.username ?? '—'}</span>
      },
    },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'createdAt', label: 'Date', render: (v) => <span className="text-gray-400 text-xs">{new Date(String(v)).toLocaleDateString()}</span> },
    {
      key: 'id', label: 'Actions',
      render: (_, row) => (
        <button onClick={() => { setSelectedDispute(row); setViewModal(true) }} className="p-1.5 hover:bg-primary/10 rounded text-primary">
          <Eye className="h-4 w-4" />
        </button>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3">
        <SearchInput onSearch={setSearch} placeholder="Search disputes..." className="flex-1 min-w-[200px]" />
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
          <option value="">All Statuses</option>
          <option value="open">Open</option>
          <option value="investigating">Investigating</option>
          <option value="resolved">Resolved</option>
          <option value="rejected">Rejected</option>
        </select>
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
          <option value="">All Types</option>
          <option value="ludo">Ludo</option>
          <option value="tournament">Tournament</option>
          <option value="payment">Payment</option>
        </select>
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
      </div>

      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data?.disputes ?? []}
          isLoading={isLoading}
          total={data?.total ?? 0}
          page={pagination.page}
          limit={pagination.limit}
          onPageChange={pagination.setPage}
          rowKey={(row) => row.id}
          emptyMessage="No disputes found"
        />
      </div>

      {/* View/Resolve Modal */}
      <Modal
        isOpen={viewModal}
        onClose={() => setViewModal(false)}
        title="Dispute Details"
        size="lg"
        footer={
          selectedDispute && !['resolved', 'rejected'].includes(selectedDispute.status) ? (
            <>
              <button onClick={() => setViewModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Close</button>
              <button
                onClick={() => selectedDispute && resolveMutation.mutate({ id: selectedDispute.id, resolution, outcome })}
                disabled={resolveMutation.isPending || !resolution}
                className={`px-4 py-2 rounded-lg font-medium disabled:opacity-50 ${outcome === 'resolved' ? 'bg-secondary text-black' : 'bg-danger text-white'}`}
              >
                {resolveMutation.isPending ? 'Resolving...' : outcome === 'resolved' ? 'Resolve' : 'Reject'}
              </button>
            </>
          ) : (
            <button onClick={() => setViewModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Close</button>
          )
        }
      >
        {selectedDispute && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-surface/50 rounded-lg p-3">
                <p className="text-xs text-gray-400">Type</p>
                <p className="text-white font-medium capitalize mt-0.5">{selectedDispute.type}</p>
              </div>
              <div className="bg-surface/50 rounded-lg p-3">
                <p className="text-xs text-gray-400">Status</p>
                <div className="mt-0.5"><StatusBadge status={selectedDispute.status} /></div>
              </div>
              <div className="col-span-2 bg-surface/50 rounded-lg p-3">
                <p className="text-xs text-gray-400">Reason</p>
                <p className="text-white mt-0.5">{selectedDispute.reason}</p>
              </div>
              <div className="bg-surface/50 rounded-lg p-3">
                <p className="text-xs text-gray-400">Reported By</p>
                <p className="text-primary mt-0.5">{selectedDispute.reportedBy.username}</p>
              </div>
              <div className="bg-surface/50 rounded-lg p-3">
                <p className="text-xs text-gray-400">Date</p>
                <p className="text-white mt-0.5">{new Date(selectedDispute.createdAt).toLocaleString()}</p>
              </div>
            </div>

            {!['resolved', 'rejected'].includes(selectedDispute.status) && (
              <div className="space-y-3 border-t border-surface pt-4">
                <div className="flex gap-3">
                  <label className={`flex-1 flex items-center gap-2 p-3 rounded-lg border cursor-pointer ${outcome === 'resolved' ? 'border-secondary bg-secondary/10' : 'border-surface'}`}>
                    <input type="radio" value="resolved" checked={outcome === 'resolved'} onChange={() => setOutcome('resolved')} className="accent-secondary" />
                    <span className="text-sm text-white">Resolve in favor</span>
                  </label>
                  <label className={`flex-1 flex items-center gap-2 p-3 rounded-lg border cursor-pointer ${outcome === 'rejected' ? 'border-danger bg-danger/10' : 'border-surface'}`}>
                    <input type="radio" value="rejected" checked={outcome === 'rejected'} onChange={() => setOutcome('rejected')} className="accent-danger" />
                    <span className="text-sm text-white">Reject dispute</span>
                  </label>
                </div>
                <div>
                  <label className="block text-sm text-gray-300 mb-1">Resolution Note</label>
                  <textarea value={resolution} onChange={(e) => setResolution(e.target.value)} rows={3} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" placeholder="Explain your decision..." />
                </div>
              </div>
            )}

            {selectedDispute.resolution && (
              <div className="bg-surface/50 rounded-lg p-3 border-t border-surface">
                <p className="text-xs text-gray-400">Resolution</p>
                <p className="text-white mt-0.5">{selectedDispute.resolution}</p>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  )
}

export default DisputeManagement
