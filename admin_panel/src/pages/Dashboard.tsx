import React from 'react'
import { useQuery } from '@tanstack/react-query'
import { Users, Activity, DollarSign, TrendingUp, Gamepad2, Trophy, Clock, AlertCircle } from 'lucide-react'
import StatCard from '../components/StatCard'
import { LineChart } from '../components/charts/LineChart'
import { BarChart } from '../components/charts/BarChart'
import { PieChart } from '../components/charts/PieChart'
import StatusBadge from '../components/StatusBadge'
import LoadingSpinner from '../components/LoadingSpinner'
import { dashboardService } from '../services/dashboard.service'

const MOCK_STATS = {
  totalUsers: 12480,
  activeUsers24h: 892,
  totalRevenue: 284600,
  todayRevenue: 4820,
  activeLudoMatches: 143,
  activeTournaments: 7,
  pendingWithdrawals: 38,
  openDisputes: 12,
}

const MOCK_REVENUE = Array.from({ length: 30 }, (_, i) => ({
  date: `Day ${i + 1}`,
  deposit: Math.floor(Math.random() * 10000 + 2000),
  withdrawal: Math.floor(Math.random() * 5000 + 1000),
  entryFee: Math.floor(Math.random() * 3000 + 500),
}))

const MOCK_USERS = Array.from({ length: 30 }, (_, i) => ({
  date: `Day ${i + 1}`,
  value: Math.floor(Math.random() * 200 + 50),
}))

const MOCK_GAMES = Array.from({ length: 30 }, (_, i) => ({
  date: `Day ${i + 1}`,
  value: Math.floor(Math.random() * 300 + 100),
}))

const MOCK_REVENUE_SPLIT = [
  { name: 'Deposits', value: 45, color: '#00D4FF' },
  { name: 'Entry Fees', value: 30, color: '#00FF88' },
  { name: 'Bonuses', value: 15, color: '#9D4EDD' },
  { name: 'Other', value: 10, color: '#FF3366' },
]

const MOCK_TRANSACTIONS = [
  { id: '1', username: 'player_one', type: 'deposit', amount: 500, status: 'completed', createdAt: '2024-01-15' },
  { id: '2', username: 'gamer_pro', type: 'withdrawal', amount: 1200, status: 'pending', createdAt: '2024-01-15' },
  { id: '3', username: 'arena_king', type: 'prize', amount: 2500, status: 'completed', createdAt: '2024-01-14' },
]

const MOCK_TOURNAMENTS = [
  { id: '1', name: 'Ludo Championship', startTime: '2024-02-01T18:00', currentParticipants: 56, maxParticipants: 64, prizePool: 10000 },
  { id: '2', name: 'Weekend Battle', startTime: '2024-02-03T15:00', currentParticipants: 28, maxParticipants: 32, prizePool: 5000 },
]

const MOCK_DISPUTES = [
  { id: '1', reason: 'Result mismatch', status: 'open', createdAt: '2024-01-15', reportedBy: { username: 'user123' } },
  { id: '2', reason: 'Payment issue', status: 'investigating', createdAt: '2024-01-14', reportedBy: { username: 'gamer99' } },
]

export function Dashboard() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardService.getStats,
    placeholderData: MOCK_STATS,
  })

  const { data: revenueChart } = useQuery({
    queryKey: ['revenue-chart'],
    queryFn: () => dashboardService.getRevenueChart(30),
  })

  const { data: usersChart } = useQuery({
    queryKey: ['users-chart'],
    queryFn: () => dashboardService.getUsersChart(30),
  })

  const { data: gamesChart } = useQuery({
    queryKey: ['games-chart'],
    queryFn: () => dashboardService.getGamesChart(30),
  })

  const displayStats = stats ?? MOCK_STATS

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      {statsLoading ? (
        <div className="flex justify-center py-10"><LoadingSpinner size="lg" /></div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard title="Total Users" value={displayStats.totalUsers} icon={Users} color="primary" change={8.2} />
          <StatCard title="Active Users (24h)" value={displayStats.activeUsers24h} icon={Activity} color="secondary" change={3.1} />
          <StatCard title="Total Revenue" value={displayStats.totalRevenue} prefix="₹" icon={DollarSign} color="accent" change={12.5} />
          <StatCard title="Today's Revenue" value={displayStats.todayRevenue} prefix="₹" icon={TrendingUp} color="primary" change={-2.3} />
          <StatCard title="Active Ludo Matches" value={displayStats.activeLudoMatches} icon={Gamepad2} color="secondary" />
          <StatCard title="Active Tournaments" value={displayStats.activeTournaments} icon={Trophy} color="accent" />
          <StatCard title="Pending Withdrawals" value={displayStats.pendingWithdrawals} icon={Clock} color="danger" change={5} />
          <StatCard title="Open Disputes" value={displayStats.openDisputes} icon={AlertCircle} color="danger" />
        </div>
      )}

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">Revenue (30 days)</h3>
          <LineChart
            data={(revenueChart ?? MOCK_REVENUE) as unknown as Record<string, unknown>[]}
            lines={[
              { key: 'deposit', label: 'Deposits', color: '#00D4FF' },
              { key: 'withdrawal', label: 'Withdrawals', color: '#FF3366' },
              { key: 'entryFee', label: 'Entry Fees', color: '#00FF88' },
            ]}
          />
        </div>

        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">New Users (30 days)</h3>
          <BarChart
            data={(usersChart ?? MOCK_USERS) as unknown as Record<string, unknown>[]}
            bars={[{ key: 'value', label: 'New Users', color: '#00D4FF' }]}
          />
        </div>

        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">Revenue Split</h3>
          <PieChart data={MOCK_REVENUE_SPLIT} />
        </div>

        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">Games Played (30 days)</h3>
          <LineChart
            data={(gamesChart ?? MOCK_GAMES) as unknown as Record<string, unknown>[]}
            lines={[{ key: 'value', label: 'Games', color: '#9D4EDD' }]}
          />
        </div>
      </div>

      {/* Tables */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Transactions */}
        <div className="lg:col-span-2 bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">Recent Transactions</h3>
          <div className="space-y-3">
            {MOCK_TRANSACTIONS.map((tx) => (
              <div key={tx.id} className="flex items-center justify-between py-2 border-b border-surface last:border-0">
                <div>
                  <p className="text-sm text-white font-medium">{tx.username}</p>
                  <p className="text-xs text-gray-400">{tx.type} · {tx.createdAt}</p>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`text-sm font-semibold ${tx.type === 'withdrawal' ? 'text-danger' : 'text-secondary'}`}>
                    {tx.type === 'withdrawal' ? '-' : '+'}₹{tx.amount.toLocaleString()}
                  </span>
                  <StatusBadge status={tx.status} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Upcoming Tournaments */}
        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-4">Upcoming Tournaments</h3>
          <div className="space-y-3">
            {MOCK_TOURNAMENTS.map((t) => (
              <div key={t.id} className="p-3 bg-surface/50 rounded-lg">
                <p className="text-sm text-white font-medium">{t.name}</p>
                <p className="text-xs text-gray-400 mt-1">Prize Pool: ₹{t.prizePool.toLocaleString()}</p>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs text-primary">{t.currentParticipants}/{t.maxParticipants}</span>
                  <span className="text-xs text-gray-400">{new Date(t.startTime).toLocaleDateString()}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Disputes */}
      <div className="bg-card border border-surface rounded-xl p-5">
        <h3 className="text-white font-semibold mb-4">Recent Disputes</h3>
        <div className="space-y-3">
          {MOCK_DISPUTES.map((d) => (
            <div key={d.id} className="flex items-center justify-between py-2 border-b border-surface last:border-0">
              <div>
                <p className="text-sm text-white">{d.reason}</p>
                <p className="text-xs text-gray-400">by {d.reportedBy.username} · {d.createdAt}</p>
              </div>
              <StatusBadge status={d.status} />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default Dashboard
