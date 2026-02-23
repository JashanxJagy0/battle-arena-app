import React from 'react'
import {
  PieChart as RePieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts'

interface PieChartProps {
  data: Array<{ name: string; value: number; color: string }>
  height?: number
  innerRadius?: number
}

export function PieChart({ data, height = 300, innerRadius = 60 }: PieChartProps) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <RePieChart>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={innerRadius}
          outerRadius={innerRadius + 60}
          paddingAngle={2}
          dataKey="value"
        >
          {data.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{ background: '#141729', border: '1px solid #1A1F3D', borderRadius: 8, color: '#e2e8f0' }}
        />
        <Legend
          wrapperStyle={{ color: '#9ca3af', fontSize: 12 }}
          formatter={(value) => <span style={{ color: '#9ca3af' }}>{value}</span>}
        />
      </RePieChart>
    </ResponsiveContainer>
  )
}

export default PieChart
