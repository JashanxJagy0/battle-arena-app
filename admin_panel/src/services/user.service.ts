import api from './api'

export interface User {
  id: string
  username: string
  email: string
  phone?: string
  avatar?: string
  role: string
  status: 'active' | 'banned' | 'suspended'
  balance: number
  totalGames: number
  wins: number
  losses: number
  winRate: number
  createdAt: string
  lastActiveAt?: string
  banReason?: string
}

export interface UsersResponse {
  users: User[]
  total: number
  page: number
  limit: number
}

export interface UserFilters {
  page?: number
  limit?: number
  search?: string
  role?: string
  status?: string
  startDate?: string
  endDate?: string
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

export const userService = {
  async getUsers(filters: UserFilters = {}): Promise<UsersResponse> {
    const { data } = await api.get<UsersResponse>('/admin/users', { params: filters })
    return data
  },

  async getUser(id: string): Promise<User> {
    const { data } = await api.get<User>(`/admin/users/${id}`)
    return data
  },

  async updateUser(id: string, updates: Partial<User>): Promise<User> {
    const { data } = await api.put<User>(`/admin/users/${id}`, updates)
    return data
  },

  async banUser(id: string, reason: string): Promise<User> {
    const { data } = await api.post<User>(`/admin/users/${id}/ban`, { reason })
    return data
  },

  async unbanUser(id: string): Promise<User> {
    const { data } = await api.post<User>(`/admin/users/${id}/unban`)
    return data
  },

  async creditUser(id: string, amount: number, note: string): Promise<void> {
    await api.post(`/admin/users/${id}/credit`, { amount, note })
  },

  async debitUser(id: string, amount: number, note: string): Promise<void> {
    await api.post(`/admin/users/${id}/debit`, { amount, note })
  },

  async getUserTransactions(id: string, params = {}): Promise<unknown> {
    const { data } = await api.get(`/admin/users/${id}/transactions`, { params })
    return data
  },

  async getUserGameHistory(id: string, params = {}): Promise<unknown> {
    const { data } = await api.get(`/admin/users/${id}/games`, { params })
    return data
  },
}
