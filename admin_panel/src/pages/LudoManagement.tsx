import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Eye } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import SearchInput from '../components/SearchInput'
import DateRangePicker from '../components/DateRangePicker'
import { ludoService, LudoMatch } from '../services/ludo.service'
import { usePagination } from '../hooks/usePagination'

export function LudoManagement() {
  const qc = useQueryClient()
  const pagination = usePagination(20)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [selectedMatch, setSelectedMatch] = useState<LudoMatch | null>(null)
  const [viewModal, setViewModal] = useState(false)
  const [resolveModal, setResolveModal] = useState(false)
  const [resolveWinner, setResolveWinner] = useState('')
  const [resolveReason, setResolveReason] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['ludo-matches', pagination.page, search, statusFilter, startDate, endDate],
    queryFn: () => ludoService.getMatches({
      page: pagination.page,
      limit: pagination.limit,
      search: search || undefined,
      status: statusFilter || undefined,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
    }),
    placeholderData: { matches: [], total: 0, page: 1, limit: 20 },
  })

  const resolveMutation = useMutation({
    mutationFn: ({ matchId, winnerId, reason }: { matchId: string; winnerId: string; reason: string }) =>
      ludoService.resolveDispute(matchId, winnerId, reason),
    onSuccess: () => {
      toast.success('Dispute resolved!')
      qc.invalidateQueries({ queryKey: ['ludo-matches'] })
      setResolveModal(false)
    },
    onError: () => toast.error('Failed to resolve dispute'),
  })

  const columns: Column<LudoMatch>[] = [
    { key: 'matchCode', label: 'Match Code', render: (v) => <span className="font-mono text-primary">{String(v)}</span> },
    {
      key: 'players', label: 'Players',
      render: (v) => {
        const players = v as LudoMatch['players']
        return <span className="text-gray-300">{Array.isArray(players) ? players.map(p => p.username).join(' vs ') : '—'}</span>
      },
    },
    { key: 'entryFee', label: 'Entry Fee', render: (v) => `₹${Number(v).toLocaleString()}` },
    { key: 'prizeAmount', label: 'Prize', render: (v) => <span className="text-secondary">₹{Number(v).toLocaleString()}</span> },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'hasDispute', label: 'Dispute', render: (v) => v ? <span className="text-danger text-xs font-medium">⚠ Disputed</span> : <span className="text-gray-400 text-xs">—</span> },
    { key: 'createdAt', label: 'Created', render: (v) => <span className="text-gray-400 text-xs">{new Date(String(v)).toLocaleDateString()}</span> },
    {
      key: 'id', label: 'Actions',
      render: (_, row) => (
        <div className="flex gap-1">
          <button onClick={() => { setSelectedMatch(row); setViewModal(true) }} className="p-1.5 hover:bg-primary/10 rounded text-primary" title="View">
            <Eye className="h-4 w-4" />
          </button>
          {row.hasDispute && (
            <button
              onClick={() => { setSelectedMatch(row); setResolveModal(true) }}
              className="px-2 py-1 bg-danger/10 text-danger rounded text-xs hover:bg-danger/20 transition-colors"
            >
              Resolve
            </button>
          )}
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3">
        <SearchInput onSearch={setSearch} placeholder="Search matches..." className="flex-1 min-w-[200px]" />
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
          <option value="">All Statuses</option>
          <option value="waiting">Waiting</option>
          <option value="ongoing">Ongoing</option>
          <option value="completed">Completed</option>
          <option value="disputed">Disputed</option>
          <option value="cancelled">Cancelled</option>
        </select>
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
      </div>

      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data?.matches ?? []}
          isLoading={isLoading}
          total={data?.total ?? 0}
          page={pagination.page}
          limit={pagination.limit}
          onPageChange={pagination.setPage}
          rowKey={(row) => row.id}
          emptyMessage="No matches found"
        />
      </div>

      {/* View Modal */}
      <Modal isOpen={viewModal} onClose={() => setViewModal(false)} title="Match Details" size="lg">
        {selectedMatch && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              {[
                ['Match Code', selectedMatch.matchCode],
                ['Status', selectedMatch.status],
                ['Entry Fee', `₹${selectedMatch.entryFee}`],
                ['Prize Amount', `₹${selectedMatch.prizeAmount}`],
                ['Started At', selectedMatch.startedAt ? new Date(selectedMatch.startedAt).toLocaleString() : '—'],
                ['Completed At', selectedMatch.completedAt ? new Date(selectedMatch.completedAt).toLocaleString() : '—'],
              ].map(([label, value]) => (
                <div key={String(label)} className="bg-surface/50 rounded-lg p-3">
                  <p className="text-xs text-gray-400">{label}</p>
                  <p className="text-white font-medium mt-0.5">{String(value)}</p>
                </div>
              ))}
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-2">Players</p>
              <div className="space-y-2">
                {selectedMatch.players.map((player, idx) => (
                  <div key={idx} className="flex items-center justify-between bg-surface/50 rounded-lg p-3">
                    <div className="flex items-center gap-2">
                      <div className={`h-6 w-6 rounded-full`} style={{ background: player.color }} />
                      <span className="text-white text-sm">{player.username}</span>
                    </div>
                    {player.result && <StatusBadge status={player.result} />}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </Modal>

      {/* Resolve Dispute Modal */}
      <Modal
        isOpen={resolveModal}
        onClose={() => setResolveModal(false)}
        title="Resolve Dispute"
        size="md"
        footer={
          <>
            <button onClick={() => setResolveModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={() => selectedMatch && resolveWinner && resolveMutation.mutate({ matchId: selectedMatch.id, winnerId: resolveWinner, reason: resolveReason })}
              disabled={resolveMutation.isPending || !resolveWinner}
              className="px-4 py-2 bg-secondary text-black rounded-lg font-medium disabled:opacity-50"
            >
              {resolveMutation.isPending ? 'Resolving...' : 'Resolve'}
            </button>
          </>
        }
      >
        {selectedMatch && (
          <div className="space-y-4">
            <p className="text-gray-400 text-sm">Select the winner to resolve this dispute for match <span className="text-primary font-mono">{selectedMatch.matchCode}</span></p>
            <div>
              <label className="block text-sm text-gray-300 mb-2">Select Winner</label>
              <div className="space-y-2">
                {selectedMatch.players.map((player, idx) => (
                  <label key={idx} className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${resolveWinner === player.userId ? 'border-secondary bg-secondary/10' : 'border-surface hover:border-surface/80'}`}>
                    <input type="radio" value={player.userId} checked={resolveWinner === player.userId} onChange={(e) => setResolveWinner(e.target.value)} className="accent-secondary" />
                    <span className="text-white">{player.username}</span>
                  </label>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm text-gray-300 mb-1">Resolution Reason</label>
              <textarea value={resolveReason} onChange={(e) => setResolveReason(e.target.value)} rows={3} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" placeholder="Explain your decision..." />
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}

export default LudoManagement
