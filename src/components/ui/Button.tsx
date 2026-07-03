import React from "react";
import { Loader2 } from "lucide-react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "outline" | "danger" | "glowing-run";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
}

export function Button({
  children,
  className = "",
  variant = "secondary",
  size = "md",
  isLoading = false,
  disabled,
  ...props
}: ButtonProps) {
  let baseStyles = "relative inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/50 active:scale-95 disabled:opacity-50 disabled:pointer-events-none disabled:active:scale-100 ";

  // Sizes
  if (size === "sm") baseStyles += "px-3 py-1.5 text-xs ";
  else if (size === "md") baseStyles += "px-4 py-2 text-sm ";
  else if (size === "lg") baseStyles += "px-6 py-3 text-base ";

  // Variants
  if (variant === "primary") {
    baseStyles += "bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/20 ";
  } else if (variant === "secondary") {
    baseStyles += "bg-white/5 border border-white/10 hover:bg-white/10 text-neutral-200 ";
  } else if (variant === "ghost") {
    baseStyles += "bg-transparent hover:bg-white/5 text-neutral-400 hover:text-white ";
  } else if (variant === "outline") {
    baseStyles += "bg-transparent border border-white/20 hover:border-white/40 text-neutral-300 ";
  } else if (variant === "danger") {
    baseStyles += "bg-red-600/80 hover:bg-red-500 text-white border border-red-500/20 ";
  } else if (variant === "glowing-run") {
    baseStyles += "bg-indigo-600 hover:bg-indigo-500 text-white font-semibold shadow-[0_0_15px_rgba(99,102,241,0.5)] border border-indigo-400/30 animate-glow-pulse ";
  }

  const isBtnDisabled = disabled || isLoading;

  return (
    <button
      className={`${baseStyles} ${className}`}
      disabled={isBtnDisabled}
      aria-busy={isLoading}
      aria-disabled={isBtnDisabled}
      {...props}
    >
      {isLoading && (
        <Loader2 className="w-3.5 h-3.5 mr-2 animate-spin text-current" />
      )}
      {children}
    </button>
  );
}
