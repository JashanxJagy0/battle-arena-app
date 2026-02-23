import api from './api'

export interface PromoCode {
  id: string
  code: string
  type: 'percentage' | 'fixed'
  value: number
  minDeposit?: number
  maxDiscount?: number
  usageLimit?: number
  usedCount: number
  isActive: boolean
  expiresAt?: string
  createdAt: string
}

export const promoService = {
  async getPromoCodes(): Promise<PromoCode[]> {
    const { data } = await api.get<PromoCode[]>('/admin/promo-codes')
    return data
  },

  async createPromoCode(promo: Partial<PromoCode>): Promise<PromoCode> {
    const { data } = await api.post<PromoCode>('/admin/promo-codes', promo)
    return data
  },

  async updatePromoCode(id: string, updates: Partial<PromoCode>): Promise<PromoCode> {
    const { data } = await api.put<PromoCode>(`/admin/promo-codes/${id}`, updates)
    return data
  },

  async deletePromoCode(id: string): Promise<void> {
    await api.delete(`/admin/promo-codes/${id}`)
  },

  async togglePromoCode(id: string): Promise<PromoCode> {
    const { data } = await api.post<PromoCode>(`/admin/promo-codes/${id}/toggle`)
    return data
  },
}
