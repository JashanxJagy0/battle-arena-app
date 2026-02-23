import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'react-hot-toast'
import App from './App'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
      <Toaster
        position="top-right"
        toastOptions={{
          style: {
            background: '#1A1F3D',
            color: '#e2e8f0',
            border: '1px solid #00D4FF33',
          },
          success: { iconTheme: { primary: '#00FF88', secondary: '#0A0E21' } },
          error: { iconTheme: { primary: '#FF3366', secondary: '#0A0E21' } },
        }}
      />
    </QueryClientProvider>
  </React.StrictMode>,
)
