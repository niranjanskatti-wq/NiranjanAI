import React from "react";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "premium" | "terminal";
  hoverEffect?: boolean;
}

export function Card({
  children,
  className = "",
  variant = "default",
  hoverEffect = true,
  ...props
}: CardProps) {
  let baseStyles = "rounded-xl border transition-all duration-300 ";
  
  if (variant === "default") {
    baseStyles += "glass-panel bg-neutral-950/40 text-neutral-100 ";
  } else if (variant === "premium") {
    baseStyles += "glass-panel bg-neutral-950/60 border-indigo-500/20 text-neutral-100 shadow-[0_0_15px_rgba(99,102,241,0.05)] ";
  } else if (variant === "terminal") {
    baseStyles += "bg-black/90 border-neutral-800 text-green-400 font-mono text-sm shadow-inner ";
  }

  if (hoverEffect && variant !== "terminal") {
    baseStyles += "premium-glow-hover hover:scale-[1.005] ";
  }

  return (
    <div className={`${baseStyles} ${className}`} {...props}>
      {children}
    </div>
  );
}
