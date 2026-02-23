import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Edit, Send } from 'lucide-react'
import toast from 'react-hot-toast'
import Modal from '../components/Modal'
import LoadingSpinner from '../components/LoadingSpinner'
import { bonusService, BonusSchedule } from '../services/bonus.service'

export function BonusManagement() {
  const qc = useQueryClient()
  const [editSchedule, setEditSchedule] = useState<BonusSchedule | null>(null)
  const [editAmount, setEditAmount] = useState(0)
  const [editActive, setEditActive] = useState(true)
  const [bulkModal, setBulkModal] = useState(false)
  const [bulkAmount, setBulkAmount] = useState('')
  const [bulkNote, setBulkNote] = useState('')
  const [filterAll, setFilterAll] = useState(true)

  const { data: schedules, isLoading } = useQuery({
    queryKey: ['bonus-schedules'],
    queryFn: bonusService.getSchedules,
    placeholderData: [],
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<BonusSchedule> }) => bonusService.updateSchedule(id, updates),
    onSuccess: () => { toast.success('Schedule updated!'); qc.invalidateQueries({ queryKey: ['bonus-schedules'] }); setEditSchedule(null) },
    onError: () => toast.error('Failed to update schedule'),
  })

  const bulkMutation = useMutation({
    mutationFn: () => bonusService.sendBulkBonus({ filterAll, amount: Number(bulkAmount), note: bulkNote }),
    onSuccess: (d) => { toast.success(`Bonus sent to ${d.sent} users!`); qc.invalidateQueries({ queryKey: ['bonus-schedules'] }); setBulkModal(false) },
    onError: () => toast.error('Failed to send bulk bonus'),
  })

  return (
    <div className="space-y-5">
      <div className="flex justify-end">
        <button onClick={() => setBulkModal(true)} className="flex items-center gap-2 px-4 py-2 bg-accent text-white rounded-lg font-medium hover:bg-accent/80 transition-colors">
          <Send className="h-4 w-4" /> Send Bulk Bonus
        </button>
      </div>

      {/* Bonus Schedules */}
      <div className="bg-card border border-surface rounded-xl p-5">
        <h2 className="text-white font-semibold mb-4">Bonus Schedules</h2>
        {isLoading ? (
          <div className="flex justify-center py-10"><LoadingSpinner /></div>
        ) : (
          <div className="space-y-3">
            {(schedules ?? []).length === 0 && (
              <p className="text-gray-400 text-center py-8">No bonus schedules configured</p>
            )}
            {(schedules ?? []).map((schedule) => (
              <div key={schedule.id} className="flex items-center justify-between p-4 bg-surface/50 rounded-lg border border-surface">
                <div>
                  <p className="text-white font-medium capitalize">{schedule.name}</p>
                  <p className="text-gray-400 text-sm mt-0.5">Type: {schedule.type.replace('_', ' ')} · Amount: ₹{schedule.amount.toLocaleString()}</p>
                </div>
                <div className="flex items-center gap-3">
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={schedule.isActive}
                      onChange={() => updateMutation.mutate({ id: schedule.id, updates: { isActive: !schedule.isActive } })}
                      className="sr-only peer"
                    />
                    <div className="w-10 h-5 bg-surface rounded-full peer peer-checked:after:translate-x-5 after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-secondary" />
                  </label>
                  <button onClick={() => { setEditSchedule(schedule); setEditAmount(schedule.amount); setEditActive(schedule.isActive) }} className="p-1.5 hover:bg-accent/10 rounded text-accent">
                    <Edit className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Edit Schedule Modal */}
      <Modal
        isOpen={!!editSchedule}
        onClose={() => setEditSchedule(null)}
        title={`Edit: ${editSchedule?.name}`}
        size="sm"
        footer={
          <>
            <button onClick={() => setEditSchedule(null)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={() => editSchedule && updateMutation.mutate({ id: editSchedule.id, updates: { amount: editAmount, isActive: editActive } })}
              disabled={updateMutation.isPending}
              className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50"
            >
              {updateMutation.isPending ? 'Saving...' : 'Save'}
            </button>
          </>
        }
      >
        <div className="space-y-3">
          <div>
            <label className="block text-sm text-gray-300 mb-1">Amount (₹)</label>
            <input type="number" value={editAmount} onChange={(e) => setEditAmount(Number(e.target.value))} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
          </div>
          <div className="flex items-center gap-3">
            <input type="checkbox" id="active" checked={editActive} onChange={(e) => setEditActive(e.target.checked)} className="accent-secondary" />
            <label htmlFor="active" className="text-sm text-gray-300">Active</label>
          </div>
        </div>
      </Modal>

      {/* Bulk Bonus Modal */}
      <Modal
        isOpen={bulkModal}
        onClose={() => setBulkModal(false)}
        title="Send Bulk Bonus"
        size="sm"
        footer={
          <>
            <button onClick={() => setBulkModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button
              onClick={() => bulkMutation.mutate()}
              disabled={bulkMutation.isPending || !bulkAmount || !bulkNote}
              className="px-4 py-2 bg-accent text-white rounded-lg font-medium disabled:opacity-50"
            >
              {bulkMutation.isPending ? 'Sending...' : 'Send Bonus'}
            </button>
          </>
        }
      >
        <div className="space-y-4">
          <div className="flex items-center gap-3 p-3 bg-surface/50 rounded-lg">
            <input type="checkbox" id="filterAll" checked={filterAll} onChange={(e) => setFilterAll(e.target.checked)} className="accent-secondary" />
            <label htmlFor="filterAll" className="text-sm text-gray-300">Send to all users</label>
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Amount (₹)</label>
            <input type="number" value={bulkAmount} onChange={(e) => setBulkAmount(e.target.value)} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Bonus amount per user" />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Note</label>
            <input value={bulkNote} onChange={(e) => setBulkNote(e.target.value)} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Reason for bonus" />
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default BonusManagement
