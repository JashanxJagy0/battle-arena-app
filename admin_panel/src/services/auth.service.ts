import api from './api'

export interface LoginCredentials {
  email: string
  password: string
}

export interface AdminUser {
  id: string
  email: string
  name: string
  role: string
  avatar?: string
}

export interface AuthResponse {
  token: string
  user: AdminUser
}

export const authService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const { data } = await api.post<AuthResponse>('/admin/auth/login', credentials)
    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_user', JSON.stringify(data.user))
    return data
  },

  logout(): void {
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    window.location.href = '/login'
  },

  getToken(): string | null {
    return localStorage.getItem('admin_token')
  },

  getUser(): AdminUser | null {
    const user = localStorage.getItem('admin_user')
    return user ? JSON.parse(user) : null
  },

  isAuthenticated(): boolean {
    return !!localStorage.getItem('admin_token')
  },
}
