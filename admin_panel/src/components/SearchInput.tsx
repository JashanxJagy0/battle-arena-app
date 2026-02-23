import React, { useState } from 'react'
import { Search, X } from 'lucide-react'
import { useDebounce } from '../hooks/useDebounce'

interface SearchInputProps {
  onSearch: (value: string) => void
  placeholder?: string
  className?: string
  delay?: number
}

export function SearchInput({ onSearch, placeholder = 'Search...', className = '', delay = 400 }: SearchInputProps) {
  const [value, setValue] = useState('')
  const debouncedValue = useDebounce(value, delay)

  React.useEffect(() => {
    onSearch(debouncedValue)
  }, [debouncedValue, onSearch])

  return (
    <div className={`relative ${className}`}>
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        className="w-full bg-surface border border-surface rounded-lg pl-10 pr-9 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-colors"
      />
      {value && (
        <button
          onClick={() => setValue('')}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
        >
          <X className="h-4 w-4" />
        </button>
      )}
    </div>
  )
}

export default SearchInput
