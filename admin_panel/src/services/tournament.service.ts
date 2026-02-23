import api from './api'

export interface PrizeDistribution {
  rank: number
  percentage: number
  amount?: number
}

export interface Tournament {
  id: string
  name: string
  gameType: string
  status: 'draft' | 'open' | 'ongoing' | 'completed' | 'cancelled'
  entryFee: number
  prizePool: number
  maxParticipants: number
  currentParticipants: number
  startTime: string
  endTime?: string
  roomId?: string
  roomPassword?: string
  prizeDistribution: PrizeDistribution[]
  createdAt: string
  rules?: string
  description?: string
}

export interface TournamentFilters {
  page?: number
  limit?: number
  search?: string
  status?: string
  gameType?: string
  startDate?: string
  endDate?: string
}

export interface TournamentsResponse {
  tournaments: Tournament[]
  total: number
  page: number
  limit: number
}

export const tournamentService = {
  async getTournaments(filters: TournamentFilters = {}): Promise<TournamentsResponse> {
    const { data } = await api.get<TournamentsResponse>('/admin/tournaments', { params: filters })
    return data
  },

  async getTournament(id: string): Promise<Tournament> {
    const { data } = await api.get<Tournament>(`/admin/tournaments/${id}`)
    return data
  },

  async createTournament(tournament: Partial<Tournament>): Promise<Tournament> {
    const { data } = await api.post<Tournament>('/admin/tournaments', tournament)
    return data
  },

  async updateTournament(id: string, updates: Partial<Tournament>): Promise<Tournament> {
    const { data } = await api.put<Tournament>(`/admin/tournaments/${id}`, updates)
    return data
  },

  async cancelTournament(id: string, reason: string): Promise<Tournament> {
    const { data } = await api.post<Tournament>(`/admin/tournaments/${id}/cancel`, { reason })
    return data
  },

  async setRoom(id: string, roomId: string, roomPassword: string): Promise<Tournament> {
    const { data } = await api.post<Tournament>(`/admin/tournaments/${id}/room`, { roomId, roomPassword })
    return data
  },

  async publishResults(id: string, results: Array<{ userId: string; rank: number }>): Promise<void> {
    await api.post(`/admin/tournaments/${id}/results`, { results })
  },
}
