import React, { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthContext, getAuthContextValue } from './hooks/useAuth'
import AdminLayout from './layouts/AdminLayout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import UserManagement from './pages/UserManagement'
import TournamentManagement from './pages/TournamentManagement'
import LudoManagement from './pages/LudoManagement'
import WalletManagement from './pages/WalletManagement'
import WithdrawalApprovals from './pages/WithdrawalApprovals'
import BonusManagement from './pages/BonusManagement'
import PromoCodeManagement from './pages/PromoCodeManagement'
import DisputeManagement from './pages/DisputeManagement'
import Analytics from './pages/Analytics'
import SettingsPage from './pages/Settings'
import AuditLogs from './pages/AuditLogs'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const token = localStorage.getItem('admin_token')
  if (!token) return <Navigate to="/login" replace />
  return <>{children}</>
}

function App() {
  const [authValue, setAuthValue] = useState(getAuthContextValue())

  useEffect(() => {
    const handleStorage = () => setAuthValue(getAuthContextValue())
    window.addEventListener('storage', handleStorage)
    return () => window.removeEventListener('storage', handleStorage)
  }, [])

  return (
    <AuthContext.Provider value={authValue}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login onLogin={() => setAuthValue(getAuthContextValue())} />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <AdminLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="users" element={<UserManagement />} />
            <Route path="tournaments" element={<TournamentManagement />} />
            <Route path="ludo" element={<LudoManagement />} />
            <Route path="wallet" element={<WalletManagement />} />
            <Route path="withdrawals" element={<WithdrawalApprovals />} />
            <Route path="bonuses" element={<BonusManagement />} />
            <Route path="promo-codes" element={<PromoCodeManagement />} />
            <Route path="disputes" element={<DisputeManagement />} />
            <Route path="analytics" element={<Analytics />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="audit-logs" element={<AuditLogs />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthContext.Provider>
  )
}

export default App
