import { useState, useCallback } from 'react'

export interface PaginationState {
  page: number
  limit: number
  total: number
}

export interface PaginationActions {
  setPage: (page: number) => void
  setLimit: (limit: number) => void
  setTotal: (total: number) => void
  nextPage: () => void
  prevPage: () => void
  totalPages: number
}

export function usePagination(initialLimit = 20): PaginationState & PaginationActions {
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(initialLimit)
  const [total, setTotal] = useState(0)

  const totalPages = Math.ceil(total / limit)

  const nextPage = useCallback(() => {
    setPage((p) => Math.min(p + 1, totalPages))
  }, [totalPages])

  const prevPage = useCallback(() => {
    setPage((p) => Math.max(p - 1, 1))
  }, [])

  const handleSetLimit = useCallback((newLimit: number) => {
    setLimit(newLimit)
    setPage(1)
  }, [])

  return { page, limit, total, totalPages, setPage, setLimit: handleSetLimit, setTotal, nextPage, prevPage }
}
