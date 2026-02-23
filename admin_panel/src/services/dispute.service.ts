import api from './api'

export interface Dispute {
  id: string
  type: 'ludo' | 'tournament' | 'payment'
  status: 'open' | 'investigating' | 'resolved' | 'rejected'
  matchId?: string
  tournamentId?: string
  transactionId?: string
  reportedBy: { id: string; username: string }
  reportedAgainst?: { id: string; username: string }
  reason: string
  evidence?: string[]
  resolution?: string
  resolvedBy?: string
  resolvedAt?: string
  createdAt: string
}

export interface DisputeFilters {
  page?: number
  limit?: number
  status?: string
  type?: string
  startDate?: string
  endDate?: string
}

export interface DisputesResponse {
  disputes: Dispute[]
  total: number
  page: number
  limit: number
}

export const disputeService = {
  async getDisputes(filters: DisputeFilters = {}): Promise<DisputesResponse> {
    const { data } = await api.get<DisputesResponse>('/admin/disputes', { params: filters })
    return data
  },

  async getDispute(id: string): Promise<Dispute> {
    const { data } = await api.get<Dispute>(`/admin/disputes/${id}`)
    return data
  },

  async resolveDispute(id: string, resolution: string, outcome: 'resolved' | 'rejected'): Promise<Dispute> {
    const { data } = await api.post<Dispute>(`/admin/disputes/${id}/resolve`, { resolution, outcome })
    return data
  },
}
