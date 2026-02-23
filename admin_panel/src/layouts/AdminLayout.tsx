import React, { useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import {
  LayoutDashboard, Users, Trophy, Gamepad2, Wallet, ArrowDownCircle,
  Gift, Tag, AlertCircle, BarChart3, Settings, FileText,
  ChevronLeft, ChevronRight, Bell, LogOut, User, Menu, X, Zap,
} from 'lucide-react'
import { useAuth } from '../hooks/useAuth'

const navItems = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/users', label: 'Users', icon: Users },
  { path: '/tournaments', label: 'Tournaments', icon: Trophy },
  { path: '/ludo', label: 'Ludo Matches', icon: Gamepad2 },
  { path: '/wallet', label: 'Wallet', icon: Wallet },
  { path: '/withdrawals', label: 'Withdrawals', icon: ArrowDownCircle },
  { path: '/bonuses', label: 'Bonuses', icon: Gift },
  { path: '/promo-codes', label: 'Promo Codes', icon: Tag },
  { path: '/disputes', label: 'Disputes', icon: AlertCircle },
  { path: '/analytics', label: 'Analytics', icon: BarChart3 },
  { path: '/settings', label: 'Settings', icon: Settings },
  { path: '/audit-logs', label: 'Audit Logs', icon: FileText },
]

function NavItem({ item, collapsed }: { item: typeof navItems[0]; collapsed: boolean }) {
  return (
    <NavLink
      to={item.path}
      end={item.path === '/'}
      className={({ isActive }) =>
        `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 group relative ${
          isActive
            ? 'bg-primary/10 text-primary border border-primary/20 shadow-neon'
            : 'text-gray-400 hover:text-white hover:bg-surface'
        }`
      }
    >
      <item.icon className="h-5 w-5 flex-shrink-0" />
      {!collapsed && <span>{item.label}</span>}
      {collapsed && (
        <div className="absolute left-full ml-2 px-2 py-1 bg-card border border-surface rounded text-xs text-white whitespace-nowrap opacity-0 group-hover:opacity-100 pointer-events-none z-50 transition-opacity">
          {item.label}
        </div>
      )}
    </NavLink>
  )
}

export function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const { user, logout } = useAuth()
  const location = useLocation()

  const pageTitle = navItems.find(n => n.path === location.pathname)?.label ?? 'Dashboard'

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 bg-black/70 z-40 lg:hidden" onClick={() => setMobileOpen(false)} />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed lg:relative z-50 lg:z-auto h-full flex flex-col bg-card border-r border-surface transition-all duration-300
          ${collapsed ? 'w-16' : 'w-60'}
          ${mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        {/* Logo */}
        <div className="flex items-center justify-between p-4 border-b border-surface h-16">
          {!collapsed && (
            <div className="flex items-center gap-2">
              <Zap className="h-7 w-7 text-primary" />
              <span className="text-white font-bold text-lg">Battle Arena</span>
            </div>
          )}
          {collapsed && <Zap className="h-7 w-7 text-primary mx-auto" />}
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="hidden lg:flex text-gray-400 hover:text-white p-1 rounded transition-colors"
          >
            {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavItem key={item.path} item={item} collapsed={collapsed} />
          ))}
        </nav>

        {/* User info */}
        <div className="p-3 border-t border-surface">
          <div className={`flex items-center gap-3 px-2 py-2 ${collapsed ? 'justify-center' : ''}`}>
            <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
              <User className="h-4 w-4 text-primary" />
            </div>
            {!collapsed && (
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-white truncate">{user?.name ?? 'Admin'}</p>
                <p className="text-xs text-gray-400 truncate">{user?.email ?? ''}</p>
              </div>
            )}
            {!collapsed && (
              <button
                onClick={logout}
                className="text-gray-400 hover:text-danger transition-colors p-1"
                title="Logout"
              >
                <LogOut className="h-4 w-4" />
              </button>
            )}
          </div>
          {collapsed && (
            <button
              onClick={logout}
              className="w-full flex justify-center mt-2 text-gray-400 hover:text-danger transition-colors p-1"
              title="Logout"
            >
              <LogOut className="h-4 w-4" />
            </button>
          )}
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top header */}
        <header className="h-16 bg-card border-b border-surface flex items-center justify-between px-4 lg:px-6 flex-shrink-0">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="lg:hidden text-gray-400 hover:text-white p-1"
            >
              {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
            <h1 className="text-lg font-semibold text-white">{pageTitle}</h1>
          </div>
          <div className="flex items-center gap-3">
            <button className="relative text-gray-400 hover:text-white p-2 rounded-lg hover:bg-surface transition-colors">
              <Bell className="h-5 w-5" />
              <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-danger" />
            </button>
            <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center cursor-pointer">
              <User className="h-4 w-4 text-primary" />
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

export default AdminLayout
