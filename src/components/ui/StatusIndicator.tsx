import React from "react";

interface StatusIndicatorProps {
  status: "online" | "warning" | "offline" | "disabled" | string;
  size?: "sm" | "md";
  showText?: boolean;
}

export function StatusIndicator({
  status,
  size = "md",
  showText = false
}: StatusIndicatorProps) {
  let colorClass = "bg-neutral-500";
  let pulseClass = "";
  let text = "Unknown";

  const s = status.toLowerCase();

  if (s === "online" || s === "healthy" || s === "completed") {
    colorClass = "bg-emerald-500";
    pulseClass = "bg-emerald-400";
    text = "Online";
  } else if (s === "warning" || s === "running") {
    colorClass = "bg-amber-500";
    pulseClass = "bg-amber-400";
    text = s === "running" ? "Running" : "Warning";
  } else if (s === "offline" || s === "failed" || s === "critical") {
    colorClass = "bg-rose-500";
    pulseClass = "bg-rose-400";
    text = s === "failed" ? "Failed" : "Offline";
  } else if (s === "disabled" || s === "queued") {
    colorClass = "bg-neutral-500";
    pulseClass = "";
    text = s === "queued" ? "Queued" : "Disabled";
  }

  const dotSize = size === "sm" ? "w-2 h-2" : "w-3 h-3";
  const ringSize = size === "sm" ? "w-4 h-4" : "w-5 h-5";

  return (
    <div className="flex items-center gap-2">
      <div className={`relative flex items-center justify-center ${dotSize}`}>
        {pulseClass && (
          <span className={`absolute inline-flex animate-ping rounded-full opacity-75 ${ringSize} ${pulseClass}`}></span>
        )}
        <span className={`relative inline-flex rounded-full ${dotSize} ${colorClass}`}></span>
      </div>
      {showText && (
        <span className="text-xs font-medium text-neutral-300 capitalize">{text}</span>
      )}
    </div>
  );
}
