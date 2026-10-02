import * as SwitchPrimitive from '@radix-ui/react-switch'
import { cn } from '@/lib/utils'

export function Switch({
  checked,
  onCheckedChange,
  disabled,
  className,
  'aria-label': ariaLabel,
}: {
  checked: boolean
  onCheckedChange: (v: boolean) => void
  disabled?: boolean
  className?: string
  'aria-label'?: string
}) {
  return (
    <SwitchPrimitive.Root
      checked={checked}
      onCheckedChange={onCheckedChange}
      disabled={disabled}
      aria-label={ariaLabel}
      className={cn(
        'peer inline-flex h-6 w-10 shrink-0 cursor-pointer items-center rounded-full border border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent/50 disabled:cursor-not-allowed disabled:opacity-45 data-[state=checked]:bg-accent data-[state=unchecked]:bg-border',
        className,
      )}
    >
      <SwitchPrimitive.Thumb className="pointer-events-none block size-5 rounded-full bg-white shadow-md ring-0 transition-transform duration-200 data-[state=checked]:translate-x-[17px] data-[state=unchecked]:translate-x-[1px]" />
    </SwitchPrimitive.Root>
  )
}
