import api from './api'

export interface BonusSchedule {
  id: string
  name: string
  type: 'daily_login' | 'weekly' | 'referral' | 'first_deposit' | 'custom'
  amount: number
  isActive: boolean
  conditions?: Record<string, unknown>
  createdAt: string
}

export interface BulkBonusPayload {
  userIds?: string[]
  filterAll?: boolean
  amount: number
  note: string
}

export const bonusService = {
  async getSchedules(): Promise<BonusSchedule[]> {
    const { data } = await api.get<BonusSchedule[]>('/admin/bonuses/schedules')
    return data
  },

  async updateSchedule(id: string, updates: Partial<BonusSchedule>): Promise<BonusSchedule> {
    const { data } = await api.put<BonusSchedule>(`/admin/bonuses/schedules/${id}`, updates)
    return data
  },

  async sendBulkBonus(payload: BulkBonusPayload): Promise<{ sent: number }> {
    const { data } = await api.post<{ sent: number }>('/admin/bonuses/bulk', payload)
    return data
  },
}
