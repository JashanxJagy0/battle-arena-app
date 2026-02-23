import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import DateRangePicker from '../components/DateRangePicker'
import { LineChart } from '../components/charts/LineChart'
import { BarChart } from '../components/charts/BarChart'
import { PieChart } from '../components/charts/PieChart'
import { dashboardService } from '../services/dashboard.service'

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

const MOCK_GAME_SPLIT = [
  { name: 'Ludo', value: 55, color: '#00D4FF' },
  { name: 'Chess', value: 25, color: '#9D4EDD' },
  { name: 'Carrom', value: 20, color: '#00FF88' },
]

const MOCK_REVENUE_SPLIT = [
  { name: 'Deposits', value: 45, color: '#00D4FF' },
  { name: 'Entry Fees', value: 30, color: '#00FF88' },
  { name: 'Bonuses', value: 15, color: '#9D4EDD' },
  { name: 'Other', value: 10, color: '#FF3366' },
]

export function Analytics() {
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [days] = useState(30)

  const { data: revenueChart } = useQuery({
    queryKey: ['revenue-chart', days],
    queryFn: () => dashboardService.getRevenueChart(days),
  })

  const { data: usersChart } = useQuery({
    queryKey: ['users-chart', days],
    queryFn: () => dashboardService.getUsersChart(days),
  })

  const { data: gamesChart } = useQuery({
    queryKey: ['games-chart', days],
    queryFn: () => dashboardService.getGamesChart(days),
  })

  return (
    <div className="space-y-6">
      {/* Date Range Selector */}
      <div className="bg-card border border-surface rounded-xl p-4 flex items-center gap-4">
        <span className="text-gray-400 text-sm">Date Range:</span>
        <DateRangePicker startDate={startDate} endDate={endDate} onStartDateChange={setStartDate} onEndDateChange={setEndDate} />
        <div className="flex gap-2 ml-auto">
          {[7, 14, 30, 90].map((d) => (
            <button key={d} className="px-3 py-1.5 rounded text-sm text-gray-400 hover:text-white hover:bg-surface transition-colors">
              {d}d
            </button>
          ))}
        </div>
      </div>

      {/* Revenue Analytics */}
      <div className="bg-card border border-surface rounded-xl p-5">
        <h3 className="text-white font-semibold mb-1">Revenue Analytics</h3>
        <p className="text-gray-400 text-sm mb-4">Deposits, withdrawals, and entry fees over time</p>
        <LineChart
          data={(revenueChart ?? MOCK_REVENUE) as unknown as Record<string, unknown>[]}
          lines={[
            { key: 'deposit', label: 'Deposits', color: '#00D4FF' },
            { key: 'withdrawal', label: 'Withdrawals', color: '#FF3366' },
            { key: 'entryFee', label: 'Entry Fees', color: '#00FF88' },
          ]}
          height={350}
        />
      </div>

      {/* User Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-1">User Growth</h3>
          <p className="text-gray-400 text-sm mb-4">New user registrations over time</p>
          <BarChart
            data={(usersChart ?? MOCK_USERS) as unknown as Record<string, unknown>[]}
            bars={[{ key: 'value', label: 'New Users', color: '#00D4FF' }]}
            height={280}
          />
        </div>

        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-1">Revenue Split</h3>
          <p className="text-gray-400 text-sm mb-4">Distribution of revenue sources</p>
          <PieChart data={MOCK_REVENUE_SPLIT} height={280} />
        </div>
      </div>

      {/* Game Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-1">Games Played</h3>
          <p className="text-gray-400 text-sm mb-4">Total games played over time</p>
          <LineChart
            data={(gamesChart ?? MOCK_GAMES) as unknown as Record<string, unknown>[]}
            lines={[{ key: 'value', label: 'Games', color: '#9D4EDD' }]}
            height={280}
          />
        </div>

        <div className="bg-card border border-surface rounded-xl p-5">
          <h3 className="text-white font-semibold mb-1">Game Distribution</h3>
          <p className="text-gray-400 text-sm mb-4">Breakdown by game type</p>
          <PieChart data={MOCK_GAME_SPLIT} height={280} />
        </div>
      </div>

      {/* Financial Summary */}
      <div className="bg-card border border-surface rounded-xl p-5">
        <h3 className="text-white font-semibold mb-4">Financial Summary</h3>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Total Deposits', value: '₹8,42,600', change: '+12.3%', color: 'text-secondary' },
            { label: 'Total Withdrawals', value: '₹5,21,400', change: '-3.1%', color: 'text-danger' },
            { label: 'Net Revenue', value: '₹3,21,200', change: '+18.5%', color: 'text-primary' },
            { label: 'Avg. Daily Revenue', value: '₹10,706', change: '+8.9%', color: 'text-accent' },
          ].map((item) => (
            <div key={item.label} className="bg-surface/50 rounded-lg p-4">
              <p className="text-xs text-gray-400">{item.label}</p>
              <p className={`text-xl font-bold mt-1 ${item.color}`}>{item.value}</p>
              <p className={`text-xs mt-1 ${item.change.startsWith('+') ? 'text-secondary' : 'text-danger'}`}>{item.change} vs last period</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default Analytics
