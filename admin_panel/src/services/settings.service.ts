import api from './api'

export interface Setting {
  key: string
  value: string | number | boolean
  type: 'string' | 'number' | 'boolean' | 'json'
  description?: string
  category?: string
}

export const settingsService = {
  async getSettings(): Promise<Setting[]> {
    const { data } = await api.get<Setting[]>('/admin/settings')
    return data
  },

  async updateSetting(key: string, value: Setting['value']): Promise<Setting> {
    const { data } = await api.put<Setting>(`/admin/settings/${key}`, { value })
    return data
  },

  async updateSettings(settings: Array<{ key: string; value: Setting['value'] }>): Promise<void> {
    await api.put('/admin/settings', { settings })
  },
}
