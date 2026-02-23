import api from './api'

export interface DashboardStats {
  totalUsers: number
  activeUsers24h: number
  totalRevenue: number
  todayRevenue: number
  activeLudoMatches: number
  activeTournaments: number
  pendingWithdrawals: number
  openDisputes: number
}

export interface ChartData {
  date: string
  value: number
}

export interface RevenueChartData {
  date: string
  deposit: number
  withdrawal: number
  entryFee: number
}

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const { data } = await api.get<DashboardStats>('/admin/dashboard/stats')
    return data
  },

  async getRevenueChart(days = 30): Promise<RevenueChartData[]> {
    const { data } = await api.get<RevenueChartData[]>('/admin/dashboard/revenue-chart', { params: { days } })
    return data
  },

  async getUsersChart(days = 30): Promise<ChartData[]> {
    const { data } = await api.get<ChartData[]>('/admin/dashboard/users-chart', { params: { days } })
    return data
  },

  async getGamesChart(days = 30): Promise<ChartData[]> {
    const { data } = await api.get<ChartData[]>('/admin/dashboard/games-chart', { params: { days } })
    return data
  },

  async getRecentTransactions(): Promise<unknown[]> {
    const { data } = await api.get('/admin/dashboard/recent-transactions')
    return data
  },

  async getUpcomingTournaments(): Promise<unknown[]> {
    const { data } = await api.get('/admin/dashboard/upcoming-tournaments')
    return data
  },

  async getRecentDisputes(): Promise<unknown[]> {
    const { data } = await api.get('/admin/dashboard/recent-disputes')
    return data
  },
}
