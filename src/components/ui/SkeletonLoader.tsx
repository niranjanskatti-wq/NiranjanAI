import React from "react";

interface SkeletonLoaderProps {
  variant?: "card" | "line" | "avatar" | "circle" | "text-block";
  count?: number;
  className?: string;
}

export function SkeletonLoader({
  variant = "card",
  count = 1,
  className = ""
}: SkeletonLoaderProps) {
  const items = Array.from({ length: count });

  const renderSkeleton = (idx: number) => {
    let classes = "animate-pulse bg-white/5 rounded-lg ";

    if (variant === "card") {
      classes += "w-full h-32 border border-white/5 ";
    } else if (variant === "line") {
      classes += "w-full h-4 ";
    } else if (variant === "avatar") {
      classes += "w-8 h-8 rounded-full ";
    } else if (variant === "circle") {
      classes += "w-12 h-12 rounded-full ";
    } else if (variant === "text-block") {
      classes += "w-full h-20 ";
    }

    return <div key={idx} className={`${classes} ${className}`} />;
  };

  return (
    <div className="space-y-3 w-full">
      {items.map((_, idx) => renderSkeleton(idx))}
    </div>
  );
}
