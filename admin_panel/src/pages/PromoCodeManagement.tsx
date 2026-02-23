import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Edit, Trash2, ToggleLeft, ToggleRight } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import DataTable, { Column } from '../components/DataTable'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { promoService, PromoCode } from '../services/promo.service'

const promoSchema = z.object({
  code: z.string().min(3, 'Code must be at least 3 characters').toUpperCase(),
  type: z.enum(['percentage', 'fixed']),
  value: z.number().min(1, 'Value must be at least 1'),
  minDeposit: z.number().optional(),
  maxDiscount: z.number().optional(),
  usageLimit: z.number().optional(),
  expiresAt: z.string().optional(),
})
type PromoForm = z.infer<typeof promoSchema>

export function PromoCodeManagement() {
  const qc = useQueryClient()
  const [createModal, setCreateModal] = useState(false)
  const [editModal, setEditModal] = useState(false)
  const [deleteConfirm, setDeleteConfirm] = useState(false)
  const [selectedPromo, setSelectedPromo] = useState<PromoCode | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['promo-codes'],
    queryFn: promoService.getPromoCodes,
    placeholderData: [],
  })

  const createMutation = useMutation({
    mutationFn: promoService.createPromoCode,
    onSuccess: () => { toast.success('Promo code created!'); qc.invalidateQueries({ queryKey: ['promo-codes'] }); setCreateModal(false) },
    onError: () => toast.error('Failed to create promo code'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<PromoCode> }) => promoService.updatePromoCode(id, updates),
    onSuccess: () => { toast.success('Promo code updated!'); qc.invalidateQueries({ queryKey: ['promo-codes'] }); setEditModal(false) },
    onError: () => toast.error('Failed to update promo code'),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => promoService.deletePromoCode(id),
    onSuccess: () => { toast.success('Promo code deleted'); qc.invalidateQueries({ queryKey: ['promo-codes'] }); setDeleteConfirm(false) },
    onError: () => toast.error('Failed to delete promo code'),
  })

  const toggleMutation = useMutation({
    mutationFn: (id: string) => promoService.togglePromoCode(id),
    onSuccess: () => { toast.success('Status toggled'); qc.invalidateQueries({ queryKey: ['promo-codes'] }) },
    onError: () => toast.error('Failed to toggle'),
  })

  const form = useForm<PromoForm>({
    resolver: zodResolver(promoSchema),
    defaultValues: { type: 'percentage', value: 10 },
  })

  const columns: Column<PromoCode>[] = [
    { key: 'code', label: 'Code', render: (v) => <span className="font-mono text-primary font-bold">{String(v)}</span> },
    { key: 'type', label: 'Type', render: (v) => <span className="capitalize text-gray-300">{String(v)}</span> },
    {
      key: 'value', label: 'Value',
      render: (v, row) => <span className="text-secondary font-medium">{row.type === 'percentage' ? `${v}%` : `₹${v}`}</span>,
    },
    { key: 'usedCount', label: 'Used', render: (v, row) => `${v}${row.usageLimit ? `/${row.usageLimit}` : ''}` },
    { key: 'expiresAt', label: 'Expires', render: (v) => v ? new Date(String(v)).toLocaleDateString() : <span className="text-gray-500">Never</span> },
    {
      key: 'isActive', label: 'Active',
      render: (v, row) => (
        <button onClick={() => toggleMutation.mutate(String(row.id))} className="text-gray-400 hover:text-white transition-colors">
          {v ? <ToggleRight className="h-6 w-6 text-secondary" /> : <ToggleLeft className="h-6 w-6" />}
        </button>
      ),
    },
    {
      key: 'id', label: 'Actions',
      render: (_, row) => (
        <div className="flex gap-1">
          <button onClick={() => { setSelectedPromo(row); form.reset({ code: row.code, type: row.type, value: row.value, minDeposit: row.minDeposit, maxDiscount: row.maxDiscount, usageLimit: row.usageLimit }); setEditModal(true) }} className="p-1.5 hover:bg-accent/10 rounded text-accent"><Edit className="h-4 w-4" /></button>
          <button onClick={() => { setSelectedPromo(row); setDeleteConfirm(true) }} className="p-1.5 hover:bg-danger/10 rounded text-danger"><Trash2 className="h-4 w-4" /></button>
        </div>
      ),
    },
  ]

  const FormFields = () => (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <div className="col-span-2">
          <label className="block text-sm text-gray-300 mb-1">Code</label>
          <input {...form.register('code')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white uppercase focus:outline-none focus:border-primary" placeholder="SUMMER50" />
          {form.formState.errors.code && <p className="text-xs text-danger mt-1">{form.formState.errors.code.message}</p>}
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Type</label>
          <select {...form.register('type')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary">
            <option value="percentage">Percentage</option>
            <option value="fixed">Fixed Amount</option>
          </select>
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Value</label>
          <input type="number" {...form.register('value', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Min Deposit (₹)</label>
          <input type="number" {...form.register('minDeposit', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Optional" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Max Discount (₹)</label>
          <input type="number" {...form.register('maxDiscount', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Optional" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Usage Limit</label>
          <input type="number" {...form.register('usageLimit', { valueAsNumber: true })} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" placeholder="Unlimited" />
        </div>
        <div>
          <label className="block text-sm text-gray-300 mb-1">Expires At</label>
          <input type="date" {...form.register('expiresAt')} className="w-full bg-surface border border-surface rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary [color-scheme:dark]" />
        </div>
      </div>
    </div>
  )

  return (
    <div className="space-y-5">
      <div className="flex justify-end">
        <button onClick={() => { form.reset({ type: 'percentage', value: 10 }); setCreateModal(true) }} className="flex items-center gap-2 px-4 py-2 bg-primary text-black rounded-lg font-medium hover:bg-primary/80 transition-colors">
          <Plus className="h-4 w-4" /> Create Promo Code
        </button>
      </div>

      <div className="bg-card border border-surface rounded-xl p-4">
        <DataTable
          columns={columns}
          data={data ?? []}
          isLoading={isLoading}
          rowKey={(row) => row.id}
          emptyMessage="No promo codes found"
        />
      </div>

      <Modal isOpen={createModal} onClose={() => setCreateModal(false)} title="Create Promo Code" size="md"
        footer={
          <>
            <button onClick={() => setCreateModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button onClick={form.handleSubmit((d) => createMutation.mutate(d))} disabled={createMutation.isPending} className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50">
              {createMutation.isPending ? 'Creating...' : 'Create'}
            </button>
          </>
        }
      >
        <FormFields />
      </Modal>

      <Modal isOpen={editModal} onClose={() => setEditModal(false)} title={`Edit: ${selectedPromo?.code}`} size="md"
        footer={
          <>
            <button onClick={() => setEditModal(false)} className="px-4 py-2 border border-surface rounded-lg text-gray-300 hover:bg-surface transition-colors">Cancel</button>
            <button onClick={form.handleSubmit((d) => selectedPromo && updateMutation.mutate({ id: selectedPromo.id, updates: d }))} disabled={updateMutation.isPending} className="px-4 py-2 bg-primary text-black rounded-lg font-medium disabled:opacity-50">
              {updateMutation.isPending ? 'Saving...' : 'Save'}
            </button>
          </>
        }
      >
        <FormFields />
      </Modal>

      <ConfirmDialog
        isOpen={deleteConfirm}
        onClose={() => setDeleteConfirm(false)}
        onConfirm={() => selectedPromo && deleteMutation.mutate(selectedPromo.id)}
        title="Delete Promo Code"
        message={`Are you sure you want to delete promo code "${selectedPromo?.code}"?`}
        confirmLabel="Delete"
        isLoading={deleteMutation.isPending}
      />
    </div>
  )
}

export default PromoCodeManagement
