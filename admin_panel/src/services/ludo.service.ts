import api from './api'

export interface LudoMatch {
  id: string
  matchCode: string
  status: 'waiting' | 'ongoing' | 'completed' | 'disputed' | 'cancelled'
  players: Array<{
    userId: string
    username: string
    avatar?: string
    color: string
    result?: 'win' | 'loss'
  }>
  entryFee: number
  prizeAmount: number
  startedAt?: string
  completedAt?: string
  hasDispute: boolean
  disputeId?: string
  createdAt: string
}

export interface LudoFilters {
  page?: number
  limit?: number
  search?: string
  status?: string
  startDate?: string
  endDate?: string
}

export interface LudoMatchesResponse {
  matches: LudoMatch[]
  total: number
  page: number
  limit: number
}

export const ludoService = {
  async getMatches(filters: LudoFilters = {}): Promise<LudoMatchesResponse> {
    const { data } = await api.get<LudoMatchesResponse>('/admin/ludo/matches', { params: filters })
    return data
  },

  async getMatch(id: string): Promise<LudoMatch> {
    const { data } = await api.get<LudoMatch>(`/admin/ludo/matches/${id}`)
    return data
  },

  async resolveDispute(matchId: string, winnerId: string, reason: string): Promise<void> {
    await api.post(`/admin/ludo/matches/${matchId}/resolve`, { winnerId, reason })
  },
}
