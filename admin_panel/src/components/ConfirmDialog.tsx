import React from 'react'
import { AlertTriangle } from 'lucide-react'
import Modal from './Modal'

interface ConfirmDialogProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  variant?: 'danger' | 'warning' | 'primary'
  isLoading?: boolean
}

const variantMap = {
  danger: 'bg-danger hover:bg-danger/80 text-white',
  warning: 'bg-yellow-500 hover:bg-yellow-400 text-black',
  primary: 'bg-primary hover:bg-primary/80 text-black',
}

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'danger',
  isLoading,
}: ConfirmDialogProps) {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={title}
      size="sm"
      footer={
        <>
          <button
            onClick={onClose}
            disabled={isLoading}
            className="px-4 py-2 rounded-lg border border-surface text-gray-300 hover:bg-surface transition-colors"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={isLoading}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${variantMap[variant]} disabled:opacity-50`}
          >
            {isLoading ? 'Processing...' : confirmLabel}
          </button>
        </>
      }
    >
      <div className="flex gap-4">
        <AlertTriangle className={`h-12 w-12 flex-shrink-0 ${variant === 'danger' ? 'text-danger' : 'text-yellow-500'}`} />
        <p className="text-gray-300">{message}</p>
      </div>
    </Modal>
  )
}

export default ConfirmDialog
