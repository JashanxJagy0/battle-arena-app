import api from './api'

export interface Transaction {
  id: string
  userId: string
  username: string
  type: 'deposit' | 'withdrawal' | 'entry_fee' | 'prize' | 'bonus' | 'refund' | 'admin_credit' | 'admin_debit'
  amount: number
  status: 'pending' | 'completed' | 'failed' | 'cancelled'
  reference?: string
  note?: string
  createdAt: string
  completedAt?: string
}

export interface TransactionFilters {
  page?: number
  limit?: number
  search?: string
  type?: string
  status?: string
  startDate?: string
  endDate?: string
  userId?: string
}

export interface TransactionsResponse {
  transactions: Transaction[]
  total: number
  page: number
  limit: number
}

export const transactionService = {
  async getTransactions(filters: TransactionFilters = {}): Promise<TransactionsResponse> {
    const { data } = await api.get<TransactionsResponse>('/admin/transactions', { params: filters })
    return data
  },

  async getWithdrawals(filters: TransactionFilters = {}): Promise<TransactionsResponse> {
    const { data } = await api.get<TransactionsResponse>('/admin/transactions/withdrawals', { params: filters })
    return data
  },

  async approveWithdrawal(id: string, note?: string): Promise<Transaction> {
    const { data } = await api.post<Transaction>(`/admin/transactions/withdrawals/${id}/approve`, { note })
    return data
  },

  async rejectWithdrawal(id: string, reason: string): Promise<Transaction> {
    const { data } = await api.post<Transaction>(`/admin/transactions/withdrawals/${id}/reject`, { reason })
    return data
  },

  async exportTransactions(filters: TransactionFilters = {}): Promise<Blob> {
    const { data } = await api.get('/admin/transactions/export', {
      params: filters,
      responseType: 'blob',
    })
    return data
  },
}
