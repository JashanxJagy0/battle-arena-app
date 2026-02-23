import React, { useState, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Eye, Edit, Ban, CheckCircle, Plus, Minus } from 'lucide-react'
import toast from 'react-hot-toast'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import DataTable, { Column } from '../components/DataTable'
import SearchInput from '../components/SearchInput'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import DateRangePicker from '../components/DateRangePicker'
import { userService, User } from '../services/user.service'
import { usePagination } from '../hooks/usePagination'

const creditSchema = z.object({
  amount: z.number().min(1, 'Amount must be at least 1'),
  note: z.string().min(1, 'Note is required'),
})
type CreditForm = z.infer<typeof creditSchema>

const banSchema = z.object({
  reason: z.string().min(5, 'Reason must be at least 5 characters'),
})
type BanForm = z.infer<typeof banSchema>

export function UserManagement() {
  const qc = useQueryClient()
  const pagination = usePagination(20)
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [role, setRole] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [viewModal, setViewModal] = useState(false)
  const [editModal, setEditModal] = useState(false)
  const [banModal, setBanModal] = useState(false)
  const [unbanConfirm, setUnbanConfirm] = useState(false)
  const [creditModal, setCreditModal] = useState(false)
  const [creditType, setCreditType] = useState<'credit' | 'debit'>('credit')

  const { data, isLoading } = useQuery({
    queryKey: ['users', pagination.page, pagination.limit, search, status, role, startDate, endDate],
    queryFn: () => userService.getUsers({
      page: pagination.page,
      limit: pagination.limit,
      search: search || undefined,
      status: status || undefined,
      role: role || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
    placeholderData: { users: [], total: 0, page: 1, limit: 20 },
  })

  const banMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => userService.banUser(id, reason),
    onSuccess: () => { toast.success('User banned'); qc.invalidateQueries({ queryKey: ['users'] }); setBanModal(false) },
    onError: () => toast.error('Failed to ban user'),
  })

  const unbanMutation = useMutation({
    mutationFn: (id: string) => userService.unbanUser(id),
    onSuccess: () => { toast.success('User unbanned'); qc.invalidateQueries({ queryKey: ['users'] }); setUnbanConfirm(false) },
    onError: () => toast.error('Failed to unban user'),
  })

  const creditMutation = useMutation({
    mutationFn: ({ id, amount, note, type }: { id: string; amount: number; note: string; type: 'credit' | 'debit' }) =>
      type === 'credit' ? userService.creditUser(id, amount, note) : userService.debitUser(id, amount, note),
    onSuccess: () => {
      toast.success(`${creditType === 'credit' ? 'Credit' : 'Debit'} successful`)
      qc.invalidateQueries({ queryKey: ['users'] })
      setCreditModal(false)
    },
    onError: () => toast.error('Operation failed'),
  })

  const banForm = useForm<BanForm>({ resolver: zodResolver(banSchema) })
  const creditForm = useForm<CreditForm>({ resolver: zodResolver(creditSchema) })

  const handleSearch = useCallback((val: string) => { setSearch(val); pagination.setPage(1) }, [pagination])

  const columns: Column<User>[] = [
    {
      key: 'avatar',
      label: '',
      render: (_v, row) => (
        <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center text-primary text-xs font-bold">
          {row.username?.toString().charAt(0).toUpperCase()}
        </div>
      ),
    },
    { key: 'username', label: 'Username', sortable: true, render: (v) => <span className="text-white font-medium">{String(v)}</span> },
    { key: 'email', label: 'Email', render: (v) => <span className="text-gray-300">{String(v)}</span> },
    { key: 'phone', label: 'Phone', render: (v) => <span className="text-gray-400">{String(v ?? '—')}</span> },
    { key: 'balance', label: 'Balance', sortable: true, render: (v) => <span className="text-secondary">₹{Number(v).toLocaleString()}</span> },
    { key: 'totalGames', label: 'Games', sortable: true },
    { key: 'winRate', label: 'Win Rate', render: (v) => <span>{Number(v).toFixed(1)}%</span> },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'createdAt', label: 'Joined', render: (v) => <span className="text-gray-400 text-xs">{new Date(String(v)).toLocaleDateString()}</span> },
    {
      key: 'id',
      label: 'Actions',
      render: (_, row) => (
        <div className="flex items-center gap-1">
          <button onClick={() => { setSelectedUser(row); setViewModal(true) }} className="p-1.5 hover:bg-primary/10 rounded text-primary transition-colors" title="View"><Eye className="h-4 w-4" /></button>
          <button onClick={() => { setSelectedUser(row); setEditModal(true) }} className="p-1.5 hover:bg-accent/10 rounded text-accent transition-colors" title="Edit"><Edit className="h-4 w-4" /></button>
          {row.status === 'banned' ? (
            <button onClick={() => { setSelectedUser(row); setUnbanConfirm(true) }} className="p-1.5 hover:bg-secondary/10 rounded text-secondary transition-colors" title="Unban"><CheckCircle className="h-4 w-4" /></button>
          ) : (
            <button onClick={() => { setSelectedUser(row); setBanModal(true) }} className="p-1.5 hover:bg-danger/10 rounded text-danger transition-colors" title="Ban"><Ban className="h-4 w-4" /></button>
          )}
          <button onClick={() => { setSelectedUser(row); setCreditType('credit'); setCreditModal(true) }} className="p-1.5 hover:bg-secondary/10 rounded text-secondary transition-colors" title="Credit"><Plus className="h-4 w-4" /></button>
          <button onClick={() => { setSelectedUser(row); setCreditType('debit'); setCreditModal(true) }} className="p-1.5 hover:bg-danger/10 rounded text-danger transition-colors" title="Debit"><Minus className="h-4 w-4" /></button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      {/* Filters */}
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3">
        <SearchInput onSearch={handleSearch} placeholder="Search users..." className="flex-1 min-w-[200px]" />
        <select value={role} onChange={(e) => setRole(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
          <option value="">All Roles</option>
          <option value="user">User</option>
          <option value="vip">VIP</option>
        </select>
        <select value={status} onChange={(e) => setStatus(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="banned">Banned</option>
          <option value="suspended">Suspended</option>
        </select>
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
      </div>

      {/* Table */}
      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data?.users ?? []}
          isLoading={isLoading}
          total={data?.total ?? 0}
          page={pagination.page}
          limit={pagination.limit}
          onPageChange={pagination.setPage}
          rowKey={(row) => row.id}
          emptyMessage="No users found"
        />
      </div>

      {/* View Modal */}
      <Modal isOpen={viewModal} onClose={() => setViewModal(false)} title="User Details" size="xl">
        {selectedUser && (
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="h-16 w-16 rounded-full bg-primary/20 flex items-center justify-center text-primary text-2xl font-bold">
                {selectedUser.username.charAt(0).toUpperCase()}
              </div>
              <div>
                <h3 className="text-xl font-bold text-white">{selectedUser.username}</h3>
                <p className="text-gray-400">{selectedUser.email}</p>
                <StatusBadge status={selectedUser.status} className="mt-1" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              {[
                ['Balance', `₹${selectedUser.balance.toLocaleString()}`],
                ['Total Games', selectedUser.totalGames],
                ['Wins', selectedUser.wins],
                ['Win Rate', `${selectedUser.winRate.toFixed(1)}%`],
                ['Role', selectedUser.role],
                ['Joined', new Date(selectedUser.createdAt).toLocaleDateString()],
              ].map(([label, value]) => (
                <div key={String(label)} className="bg-surface/50 rounded-lg p-3">
                  <p className="text-xs text-gray-400">{label}</p>
                  <p className="text-white font-medium mt-0.5">{String(value)}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </Modal>

      {/* Edit Modal */}
      <Modal isOpen={editModal} onClose={() => setEditModal(false)} title="Edit User" size="md">
        {selectedUser && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm text-gray-300 mb-1">Username</label>
              <input defaultValue={selectedUser.username} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
            </div>
            <div>
              <label className="block text-sm text-gray-300 mb-1">Email</label>
              <input defaultValue={selectedUser.email} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <button onClick={() => setEditModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
              <button className="px-4 py-2 bg-primary text-black rounded-lg font-medium">Save Changes</button>
            </div>
          </div>
        )}
      </Modal>

      {/* Ban Modal */}
      <Modal
        isOpen={banModal}
        onClose={() => setBanModal(false)}
        title={`Ban ${selectedUser?.username}`}
        size="sm"
        footer={
          <>
            <button onClick={() => setBanModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={banForm.handleSubmit((d) => selectedUser && banMutation.mutate({ id: selectedUser.id, reason: d.reason }))}
              disabled={banMutation.isPending}
              className="px-4 py-2 bg-danger text-white rounded-lg font-medium disabled:opacity-50"
            >
              {banMutation.isPending ? 'Banning...' : 'Ban User'}
            </button>
          </>
        }
      >
        <div>
          <label className="block text-sm text-gray-300 mb-1">Reason</label>
          <textarea {...banForm.register('reason')} rows={3} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" placeholder="Explain the reason for ban..." />
          {banForm.formState.errors.reason && <p className="text-xs text-danger mt-1">{banForm.formState.errors.reason.message}</p>}
        </div>
      </Modal>

      {/* Unban Confirm */}
      <ConfirmDialog
        isOpen={unbanConfirm}
        onClose={() => setUnbanConfirm(false)}
        onConfirm={() => selectedUser && unbanMutation.mutate(selectedUser.id)}
        title="Unban User"
        message={`Are you sure you want to unban ${selectedUser?.username}?`}
        confirmLabel="Unban"
        variant="primary"
        isLoading={unbanMutation.isPending}
      />

      {/* Credit/Debit Modal */}
      <Modal
        isOpen={creditModal}
        onClose={() => setCreditModal(false)}
        title={`${creditType === 'credit' ? 'Credit' : 'Debit'} - ${selectedUser?.username}`}
        size="sm"
        footer={
          <>
            <button onClick={() => setCreditModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={creditForm.handleSubmit((d) => selectedUser && creditMutation.mutate({ id: selectedUser.id, ...d, type: creditType }))}
              disabled={creditMutation.isPending}
              className={`px-4 py-2 rounded-lg font-medium disabled:opacity-50 ${creditType === 'credit' ? 'bg-secondary text-black' : 'bg-danger text-white'}`}
            >
              {creditMutation.isPending ? 'Processing...' : creditType === 'credit' ? 'Credit' : 'Debit'}
            </button>
          </>
        }
      >
        <div className="space-y-3">
          <div>
            <label className="block text-sm text-gray-300 mb-1">Amount (₹)</label>
            <input type="number" {...creditForm.register('amount', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="0" />
            {creditForm.formState.errors.amount && <p className="text-xs text-danger mt-1">{creditForm.formState.errors.amount.message}</p>}
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Note</label>
            <input {...creditForm.register('note')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Reason for adjustment" />
            {creditForm.formState.errors.note && <p className="text-xs text-danger mt-1">{creditForm.formState.errors.note.message}</p>}
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default UserManagement
