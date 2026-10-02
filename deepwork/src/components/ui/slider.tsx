import * as SliderPrimitive from '@radix-ui/react-slider'
import { cn } from '@/lib/utils'

export function Slider({
  value,
  onValueChange,
  onValueCommit,
  min = 0,
  max = 1,
  step = 0.01,
  className,
  'aria-label': ariaLabel,
}: {
  value: number
  onValueChange: (v: number) => void
  onValueCommit?: (v: number) => void
  min?: number
  max?: number
  step?: number
  className?: string
  'aria-label'?: string
}) {
  return (
    <SliderPrimitive.Root
      value={[value]}
      min={min}
      max={max}
      step={step}
      onValueChange={(v) => onValueChange(v[0])}
      onValueCommit={(v) => onValueCommit?.(v[0])}
      className={cn('relative flex h-6 w-full touch-none select-none items-center', className)}
    >
      <SliderPrimitive.Track className="relative h-1.5 w-full grow overflow-hidden rounded-full bg-border">
        <SliderPrimitive.Range className="absolute h-full bg-accent" />
      </SliderPrimitive.Track>
      <SliderPrimitive.Thumb
        aria-label={ariaLabel}
        className="block size-5 rounded-full border-2 border-accent bg-white shadow transition-transform focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-accent/30 active:scale-110"
      />
    </SliderPrimitive.Root>
  )
}
