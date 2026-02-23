import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import ConfirmDialog from '../components/ConfirmDialog'
import Modal from '../components/Modal'
import { transactionService, Transaction } from '../services/transaction.service'
import { usePagination } from '../hooks/usePagination'

type Tab = 'pending' | 'approved' | 'rejected'

export function WithdrawalApprovals() {
  const qc = useQueryClient()
  const pagination = usePagination(20)
  const [tab, setTab] = useState<Tab>('pending')
  const [selected, setSelected] = useState<Transaction | null>(null)
  const [approveConfirm, setApproveConfirm] = useState(false)
  const [rejectModal, setRejectModal] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [bulkSelected, setBulkSelected] = useState<string[]>([])

  const statusMap: Record<Tab, string> = { pending: 'pending', approved: 'completed', rejected: 'cancelled' }

  const { data, isLoading } = useQuery({
    queryKey: ['withdrawals', tab, pagination.page],
    queryFn: () => transactionService.getWithdrawals({ page: pagination.page, limit: pagination.limit, status: statusMap[tab] }),
    placeholderData: { transactions: [], total: 0, page: 1, limit: 20 },
  })

  const approveMutation = useMutation({
    mutationFn: (id: string) => transactionService.approveWithdrawal(id),
    onSuccess: () => { toast.success('Withdrawal approved!'); qc.invalidateQueries({ queryKey: ['withdrawals'] }); setApproveConfirm(false) },
    onError: () => toast.error('Failed to approve'),
  })

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => transactionService.rejectWithdrawal(id, reason),
    onSuccess: () => { toast.success('Withdrawal rejected'); qc.invalidateQueries({ queryKey: ['withdrawals'] }); setRejectModal(false) },
    onError: () => toast.error('Failed to reject'),
  })

  const toggleBulk = (id: string) => {
    setBulkSelected((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id])
  }

  const columns: Column<Transaction>[] = [
    ...(tab === 'pending' ? [{
      key: 'select',
      label: '',
      render: (_: unknown, row: Transaction) => (
        <input type="checkbox" checked={bulkSelected.includes(String(row.id))} onChange={() => toggleBulk(String(row.id))} className="accent-primary" />
      ),
    }] : []),
    { key: 'id', label: 'ID', render: (v) => <span className="font-mono text-xs text-gray-400">{String(v).slice(0, 8)}...</span> },
    { key: 'username', label: 'User', render: (v) => <span className="text-white font-medium">{String(v)}</span> },
    { key: 'amount', label: 'Amount', render: (v) => <span className="text-danger font-semibold">₹{Number(v).toLocaleString()}</span> },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'createdAt', label: 'Requested', render: (v) => new Date(String(v)).toLocaleString() },
    ...(tab === 'pending' ? [{
      key: 'actions',
      label: 'Actions',
      render: (_: unknown, row: Transaction) => (
        <div className="flex gap-2">
          <button onClick={() => { setSelected(row); setApproveConfirm(true) }} className="p-1.5 hover:bg-secondary/10 rounded text-secondary" title="Approve">
            <CheckCircle className="h-4 w-4" />
          </button>
          <button onClick={() => { setSelected(row); setRejectModal(true) }} className="p-1.5 hover:bg-danger/10 rounded text-danger" title="Reject">
            <XCircle className="h-4 w-4" />
          </button>
        </div>
      ),
    }] : []),
  ]

  const tabs: Tab[] = ['pending', 'approved', 'rejected']

  return (
    <div className="space-y-5">
      {/* Tabs */}
      <div className="flex items-center gap-2">
        {tabs.map((t) => (
          <button
            key={t}
            onClick={() => { setTab(t); setBulkSelected([]) }}
            className={`px-4 py-2 rounded-lg text-sm font-medium capitalize transition-colors ${tab === t ? 'bg-primary text-black' : 'text-gray-400 hover:text-white hover:bg-surface'}`}
          >
            {t}
          </button>
        ))}
        {tab === 'pending' && bulkSelected.length > 0 && (
          <button
            onClick={async () => {
              try {
                await Promise.all(bulkSelected.map((id) => transactionService.approveWithdrawal(id)))
                toast.success(`${bulkSelected.length} withdrawal(s) approved`)
                setBulkSelected([])
                qc.invalidateQueries({ queryKey: ['withdrawals'] })
              } catch {
                toast.error('Some approvals failed')
              }
            }}
            className="ml-auto px-4 py-2 bg-secondary text-black rounded-lg text-sm font-medium"
          >
            Approve Selected ({bulkSelected.length})
          </button>
        )}
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
          emptyMessage={`No ${tab} withdrawals`}
        />
      </div>

      <ConfirmDialog
        isOpen={approveConfirm}
        onClose={() => setApproveConfirm(false)}
        onConfirm={() => selected && approveMutation.mutate(selected.id)}
        title="Approve Withdrawal"
        message={`Approve withdrawal of ₹${selected?.amount.toLocaleString()} for ${selected?.username}?`}
        confirmLabel="Approve"
        variant="primary"
        isLoading={approveMutation.isPending}
      />

      <Modal
        isOpen={rejectModal}
        onClose={() => setRejectModal(false)}
        title="Reject Withdrawal"
        size="sm"
        footer={
          <>
            <button onClick={() => setRejectModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={() => selected && rejectMutation.mutate({ id: selected.id, reason: rejectReason })}
              disabled={rejectMutation.isPending || !rejectReason}
              className="px-4 py-2 bg-danger text-white rounded-lg font-medium disabled:opacity-50"
            >
              {rejectMutation.isPending ? 'Rejecting...' : 'Reject'}
            </button>
          </>
        }
      >
        <div>
          <label className="block text-sm text-gray-300 mb-1">Rejection Reason</label>
          <textarea value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} rows={3} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" placeholder="Provide a reason for rejection..." />
        </div>
      </Modal>
    </div>
  )
}

export default WithdrawalApprovals
