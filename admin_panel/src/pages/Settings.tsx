import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Save } from 'lucide-react'
import toast from 'react-hot-toast'
import LoadingSpinner from '../components/LoadingSpinner'
import { settingsService, Setting } from '../services/settings.service'

export function Settings() {
  const qc = useQueryClient()
  const [editedValues, setEditedValues] = useState<Record<string, string | number | boolean>>({})

  const { data: settings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: settingsService.getSettings,
    placeholderData: [
      { key: 'platform_name', value: 'Battle Arena', type: 'string', description: 'Platform display name', category: 'general' },
      { key: 'min_deposit', value: 50, type: 'number', description: 'Minimum deposit amount (₹)', category: 'wallet' },
      { key: 'max_withdrawal', value: 10000, type: 'number', description: 'Maximum withdrawal amount (₹)', category: 'wallet' },
      { key: 'withdrawal_fee_pct', value: 2, type: 'number', description: 'Withdrawal fee percentage', category: 'wallet' },
      { key: 'ludo_max_stake', value: 500, type: 'number', description: 'Maximum stake for Ludo match (₹)', category: 'games' },
      { key: 'maintenance_mode', value: false, type: 'boolean', description: 'Enable maintenance mode', category: 'general' },
      { key: 'registration_enabled', value: true, type: 'boolean', description: 'Allow new user registrations', category: 'general' },
      { key: 'referral_bonus', value: 50, type: 'number', description: 'Referral bonus amount (₹)', category: 'bonuses' },
    ] as Setting[],
  })

  const updateMutation = useMutation({
    mutationFn: ({ key, value }: { key: string; value: Setting['value'] }) => settingsService.updateSetting(key, value),
    onSuccess: () => { toast.success('Setting updated!'); qc.invalidateQueries({ queryKey: ['settings'] }) },
    onError: () => toast.error('Failed to update setting'),
  })

  const handleSave = (key: string, type: string) => {
    const rawValue = editedValues[key]
    let value: Setting['value'] = rawValue as Setting['value']
    if (type === 'number') value = Number(rawValue)
    if (type === 'boolean') value = Boolean(rawValue)
    updateMutation.mutate({ key, value })
  }

  const groupedSettings = (settings ?? []).reduce<Record<string, Setting[]>>((acc, s) => {
    const cat = s.category ?? 'general'
    if (!acc[cat]) acc[cat] = []
    acc[cat].push(s)
    return acc
  }, {})

  if (isLoading) return <div className="flex justify-center py-20"><LoadingSpinner size="lg" /></div>

  return (
    <div className="space-y-6">
      {Object.entries(groupedSettings).map(([category, categorySettings]) => (
        <div key={category} className="bg-card border border-surface rounded-xl overflow-hidden">
          <div className="px-5 py-4 border-b border-surface bg-surface/30">
            <h3 className="text-white font-semibold capitalize">{category} Settings</h3>
          </div>
          <div className="divide-y divide-surface">
            {categorySettings.map((setting) => (
              <div key={setting.key} className="flex items-center justify-between px-5 py-4 hover:bg-surface/30 transition-colors">
                <div className="flex-1 mr-6">
                  <p className="text-white font-medium text-sm font-mono">{setting.key}</p>
                  {setting.description && <p className="text-gray-400 text-xs mt-0.5">{setting.description}</p>}
                </div>
                <div className="flex items-center gap-3">
                  {setting.type === 'boolean' ? (
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        defaultChecked={Boolean(editedValues[setting.key] ?? setting.value)}
                        onChange={(e) => setEditedValues((prev) => ({ ...prev, [setting.key]: e.target.checked }))}
                        className="sr-only peer"
                      />
                      <div className="w-10 h-5 bg-surface rounded-full peer peer-checked:after:translate-x-5 after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-secondary" />
                    </label>
                  ) : (
                    <input
                      type={setting.type === 'number' ? 'number' : 'text'}
                      defaultValue={String(setting.value)}
                      onChange={(e) => setEditedValues((prev) => ({ ...prev, [setting.key]: e.target.value }))}
                      className="bg-surface border border-surface rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-primary w-48"
                    />
                  )}
                  <button
                    onClick={() => handleSave(setting.key, setting.type)}
                    disabled={updateMutation.isPending || !(setting.key in editedValues)}
                    className="p-1.5 hover:bg-primary/10 rounded text-primary disabled:opacity-30 transition-colors"
                    title="Save"
                  >
                    <Save className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

export default Settings
