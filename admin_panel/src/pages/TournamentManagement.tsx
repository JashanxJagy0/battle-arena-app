import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Edit, XCircle, Key, Award } from 'lucide-react'
import { useForm, useFieldArray } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import SearchInput from '../components/SearchInput'
import { tournamentService, Tournament } from '../services/tournament.service'
import { usePagination } from '../hooks/usePagination'

const prizeSchema = z.object({
  rank: z.number().min(1),
  percentage: z.number().min(0).max(100),
})

const tournamentSchema = z.object({
  name: z.string().min(3, 'Name too short'),
  gameType: z.string().min(1, 'Game type required'),
  entryFee: z.number().min(0),
  prizePool: z.number().min(0),
  maxParticipants: z.number().min(2),
  startTime: z.string().min(1, 'Start time required'),
  description: z.string().optional(),
  rules: z.string().optional(),
  prizeDistribution: z.array(prizeSchema).min(1, 'At least one prize rank required'),
})

type TournamentForm = z.infer<typeof tournamentSchema>

const roomSchema = z.object({
  roomId: z.string().min(1, 'Room ID required'),
  roomPassword: z.string().min(1, 'Room password required'),
})
type RoomForm = z.infer<typeof roomSchema>

function ResultsModal({ isOpen, onClose, tournament }: { isOpen: boolean; onClose: () => void; tournament: Tournament | null }) {
  const [rankInputs, setRankInputs] = useState<Record<number, string>>({ 1: '', 2: '', 3: '' })
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handlePublish = async () => {
    if (!tournament) return
    const results = Object.entries(rankInputs)
      .filter(([, userId]) => userId.trim())
      .map(([rank, userId]) => ({ rank: Number(rank), userId: userId.trim() }))
    if (results.length === 0) { toast.error('Enter at least one result'); return }
    setIsSubmitting(true)
    try {
      await tournamentService.publishResults(tournament.id, results)
      toast.success('Results published!')
      onClose()
    } catch {
      toast.error('Failed to publish results')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Publish Results - ${tournament?.name}`}
      size="md"
      footer={
        <>
          <button onClick={onClose} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
          <button onClick={handlePublish} disabled={isSubmitting} className="px-4 py-2 bg-secondary text-black rounded-lg font-medium disabled:opacity-50">
            {isSubmitting ? 'Publishing...' : 'Publish Results'}
          </button>
        </>
      }
    >
      <div className="space-y-4">
        <p className="text-gray-400 text-sm">Enter user IDs for each rank to distribute prizes.</p>
        <div className="space-y-2">
          {[1, 2, 3].map((rank) => (
            <div key={rank} className="flex items-center gap-3">
              <span className="text-gray-400 text-sm w-16">Rank {rank}</span>
              <input
                value={rankInputs[rank] ?? ''}
                onChange={(e) => setRankInputs((prev) => ({ ...prev, [rank]: e.target.value }))}
                className="flex-1 bg-surface border border-surface rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-primary"
                placeholder="User ID"
              />
            </div>
          ))}
        </div>
      </div>
    </Modal>
  )
}

export function TournamentManagement() {
  const qc = useQueryClient()
  const pagination = usePagination(20)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [selectedTournament, setSelectedTournament] = useState<Tournament | null>(null)
  const [createModal, setCreateModal] = useState(false)
  const [editModal, setEditModal] = useState(false)
  const [cancelConfirm, setCancelConfirm] = useState(false)
  const [roomModal, setRoomModal] = useState(false)
  const [resultsModal, setResultsModal] = useState(false)

  const { data, isLoading } = useQuery({
    queryKey: ['tournaments', pagination.page, search, statusFilter],
    queryFn: () => tournamentService.getTournaments({ page: pagination.page, limit: pagination.limit, search: search || undefined, status: statusFilter || undefined }),
    placeholderData: { tournaments: [], total: 0, page: 1, limit: 20 },
  })

  const createMutation = useMutation({
    mutationFn: tournamentService.createTournament,
    onSuccess: () => { toast.success('Tournament created!'); qc.invalidateQueries({ queryKey: ['tournaments'] }); setCreateModal(false) },
    onError: () => toast.error('Failed to create tournament'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<Tournament> }) => tournamentService.updateTournament(id, updates),
    onSuccess: () => { toast.success('Tournament updated!'); qc.invalidateQueries({ queryKey: ['tournaments'] }); setEditModal(false) },
    onError: () => toast.error('Failed to update tournament'),
  })

  const cancelMutation = useMutation({
    mutationFn: (id: string) => tournamentService.cancelTournament(id, 'Cancelled by admin'),
    onSuccess: () => { toast.success('Tournament cancelled'); qc.invalidateQueries({ queryKey: ['tournaments'] }); setCancelConfirm(false) },
    onError: () => toast.error('Failed to cancel tournament'),
  })

  const roomMutation = useMutation({
    mutationFn: ({ id, roomId, roomPassword }: { id: string; roomId: string; roomPassword: string }) =>
      tournamentService.setRoom(id, roomId, roomPassword),
    onSuccess: () => { toast.success('Room set!'); qc.invalidateQueries({ queryKey: ['tournaments'] }); setRoomModal(false) },
    onError: () => toast.error('Failed to set room'),
  })

  const form = useForm<TournamentForm>({
    resolver: zodResolver(tournamentSchema),
    defaultValues: { prizeDistribution: [{ rank: 1, percentage: 50 }, { rank: 2, percentage: 30 }, { rank: 3, percentage: 20 }] },
  })

  const { fields, append, remove } = useFieldArray({ control: form.control, name: 'prizeDistribution' })

  const roomForm = useForm<RoomForm>({ resolver: zodResolver(roomSchema) })

  const columns: Column<Tournament>[] = [
    { key: 'name', label: 'Tournament', sortable: true, render: (v) => <span className="text-white font-medium">{String(v)}</span> },
    { key: 'gameType', label: 'Game Type' },
    { key: 'entryFee', label: 'Entry Fee', render: (v) => `₹${Number(v).toLocaleString()}` },
    { key: 'prizePool', label: 'Prize Pool', render: (v) => <span className="text-secondary">₹{Number(v).toLocaleString()}</span> },
    { key: 'currentParticipants', label: 'Players', render: (v, row) => `${v}/${row.maxParticipants}` },
    { key: 'status', label: 'Status', render: (v) => <StatusBadge status={String(v)} /> },
    { key: 'startTime', label: 'Start Time', render: (v) => new Date(String(v)).toLocaleString() },
    {
      key: 'id', label: 'Actions',
      render: (_, row) => (
        <div className="flex gap-1">
          <button onClick={() => { setSelectedTournament(row); setEditModal(true) }} className="p-1.5 hover:bg-accent/10 rounded text-accent" title="Edit"><Edit className="h-4 w-4" /></button>
          <button onClick={() => { setSelectedTournament(row); setRoomModal(true) }} className="p-1.5 hover:bg-primary/10 rounded text-primary" title="Set Room"><Key className="h-4 w-4" /></button>
          <button onClick={() => { setSelectedTournament(row); setResultsModal(true) }} className="p-1.5 hover:bg-secondary/10 rounded text-secondary" title="Publish Results"><Award className="h-4 w-4" /></button>
          {row.status !== 'cancelled' && row.status !== 'completed' && (
            <button onClick={() => { setSelectedTournament(row); setCancelConfirm(true) }} className="p-1.5 hover:bg-danger/10 rounded text-danger" title="Cancel"><XCircle className="h-4 w-4" /></button>
          )}
        </div>
      ),
    },
  ]

  const TournamentFormFields = () => (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <div className="col-span-2">
          <label className="block text-sm text-gray-300 mb-1">Tournament Name</label>
          <input {...form.register('name')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
          {form.formState.errors.name && <p className="text-xs text-danger mt-1">{form.formState.errors.name.message}</p>}
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Game Type</label>
          <select {...form.register('gameType')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary">
            <option value="">Select game...</option>
            <option value="ludo">Ludo</option>
            <option value="chess">Chess</option>
            <option value="carrom">Carrom</option>
          </select>
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Start Time</label>
          <input type="datetime-local" {...form.register('startTime')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary [color-scheme:dark]" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Entry Fee (₹)</label>
          <input type="number" {...form.register('entryFee', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Prize Pool (₹)</label>
          <input type="number" {...form.register('prizePool', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Max Participants</label>
          <input type="number" {...form.register('maxParticipants', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
        </div>
        <div className="col-span-2">
          <label className="block text-sm text-gray-300 mb-1">Description</label>
          <textarea {...form.register('description')} rows={2} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" />
        </div>
        <div className="col-span-2">
          <label className="block text-sm text-gray-300 mb-1">Rules</label>
          <textarea {...form.register('rules')} rows={2} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary resize-none" />
        </div>
      </div>

      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm text-gray-300 font-medium">Prize Distribution</label>
          <button type="button" onClick={() => append({ rank: fields.length + 1, percentage: 0 })} className="text-xs text-primary hover:underline flex items-center gap-1">
            <Plus className="h-3 w-3" /> Add Rank
          </button>
        </div>
        <div className="space-y-2">
          {fields.map((field, idx) => (
            <div key={field.id} className="flex items-center gap-2">
              <span className="text-gray-400 text-sm w-16">Rank {idx + 1}</span>
              <input type="number" {...form.register(`prizeDistribution.${idx}.percentage`, { valueAsNumber: true })} className="flex-1 bg-surface border border-surface rounded px-2 py-1.5 text-white text-sm focus:outline-none focus:border-primary" placeholder="%" />
              <span className="text-gray-400 text-sm">%</span>
              {fields.length > 1 && (
                <button type="button" onClick={() => remove(idx)} className="text-danger hover:text-danger/80"><XCircle className="h-4 w-4" /></button>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  return (
    <div className="space-y-5">
      <div className="bg-card border border-surface rounded-xl p-4 flex flex-wrap gap-3 items-center justify-between">
        <div className="flex flex-wrap gap-3 flex-1">
          <SearchInput onSearch={setSearch} placeholder="Search tournaments..." className="flex-1 min-w-[200px]" />
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-surface border border-surface rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary">
            <option value="">All Statuses</option>
            <option value="draft">Draft</option>
            <option value="open">Open</option>
            <option value="ongoing">Ongoing</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
        <button onClick={() => { form.reset(); setCreateModal(true) }} className="flex items-center gap-2 px-4 py-2 bg-primary text-black rounded-lg font-medium hover:bg-primary/80 transition-colors">
          <Plus className="h-4 w-4" /> Create Tournament
        </button>
      </div>

      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data?.tournaments ?? []}
          isLoading={isLoading}
          total={data?.total ?? 0}
          page={pagination.page}
          limit={pagination.limit}
          onPageChange={pagination.setPage}
          rowKey={(row) => row.id}
          emptyMessage="No tournaments found"
        />
      </div>

      {/* Create Modal */}
      <Modal
        isOpen={createModal}
        onClose={() => setCreateModal(false)}
        title="Create Tournament"
        size="xl"
        footer={
          <>
            <button onClick={() => setCreateModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button onClick={form.handleSubmit((d) => createMutation.mutate(d))} disabled={createMutation.isPending} className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50">
              {createMutation.isPending ? 'Creating...' : 'Create'}
            </button>
          </>
        }
      >
        <TournamentFormFields />
      </Modal>

      {/* Edit Modal */}
      <Modal
        isOpen={editModal}
        onClose={() => setEditModal(false)}
        title={`Edit: ${selectedTournament?.name}`}
        size="xl"
        footer={
          <>
            <button onClick={() => setEditModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={form.handleSubmit((d) => selectedTournament && updateMutation.mutate({ id: selectedTournament.id, updates: d }))}
              disabled={updateMutation.isPending}
              className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50"
            >
              {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
            </button>
          </>
        }
      >
        <TournamentFormFields />
      </Modal>

      {/* Cancel Confirm */}
      <ConfirmDialog
        isOpen={cancelConfirm}
        onClose={() => setCancelConfirm(false)}
        onConfirm={() => selectedTournament && cancelMutation.mutate(selectedTournament.id)}
        title="Cancel Tournament"
        message={`Are you sure you want to cancel "${selectedTournament?.name}"? This action cannot be undone.`}
        confirmLabel="Cancel Tournament"
        isLoading={cancelMutation.isPending}
      />

      {/* Set Room Modal */}
      <Modal
        isOpen={roomModal}
        onClose={() => setRoomModal(false)}
        title={`Set Room - ${selectedTournament?.name}`}
        size="sm"
        footer={
          <>
            <button onClick={() => setRoomModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={roomForm.handleSubmit((d) => selectedTournament && roomMutation.mutate({ id: selectedTournament.id, ...d }))}
              disabled={roomMutation.isPending}
              className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50"
            >
              {roomMutation.isPending ? 'Setting...' : 'Set Room'}
            </button>
          </>
        }
      >
        <div className="space-y-3">
          <div>
            <label className="block text-sm text-gray-300 mb-1">Room ID</label>
            <input {...roomForm.register('roomId')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Enter room ID" />
            {roomForm.formState.errors.roomId && <p className="text-xs text-danger mt-1">{roomForm.formState.errors.roomId.message}</p>}
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Room Password</label>
            <input {...roomForm.register('roomPassword')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Enter room password" />
            {roomForm.formState.errors.roomPassword && <p className="text-xs text-danger mt-1">{roomForm.formState.errors.roomPassword.message}</p>}
          </div>
        </div>
      </Modal>

      {/* Results Modal */}
      <ResultsModal
        isOpen={resultsModal}
        onClose={() => setResultsModal(false)}
        tournament={selectedTournament}
      />
    </div>
  )
}

export default TournamentManagement
