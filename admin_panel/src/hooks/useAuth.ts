import { createContext, useContext } from 'react'
import { authService, AdminUser } from '../services/auth.service'

export interface AuthContextValue {
  user: AdminUser | null
  isAuthenticated: boolean
  logout: () => void
}

export const AuthContext = createContext<AuthContextValue>({
  user: null,
  isAuthenticated: false,
  logout: () => {},
})

export function useAuth(): AuthContextValue {
  return useContext(AuthContext)
}

export function getAuthContextValue(): AuthContextValue {
  return {
    user: authService.getUser(),
    isAuthenticated: authService.isAuthenticated(),
    logout: authService.logout,
  }
}
