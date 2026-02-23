import api from './api'

export interface AuditLog {
  id: string
  adminId: string
  adminName: string
  action: string
  resource: string
  resourceId?: string
  details?: Record<string, unknown>
  ipAddress?: string
  userAgent?: string
  createdAt: string
}

export interface AuditFilters {
  page?: number
  limit?: number
  adminId?: string
  action?: string
  resource?: string
  startDate?: string
  endDate?: string
}

export interface AuditLogsResponse {
  logs: AuditLog[]
  total: number
  page: number
  limit: number
}

export const auditService = {
  async getAuditLogs(filters: AuditFilters = {}): Promise<AuditLogsResponse> {
    const { data } = await api.get<AuditLogsResponse>('/admin/audit-logs', { params: filters })
    return data
  },
}
