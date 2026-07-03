"use client";

import React from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Wifi,
  Keyboard,
  Database,
  Cpu
} from "lucide-react";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

export function Footer() {
  const { fastApiUrl, activeModel } = useWorkspace();

  return (
    <footer className="h-9 bg-neutral-950 border-t border-white/5 flex items-center justify-between px-4 text-[10px] text-neutral-500 font-mono select-none shrink-0 z-10">
      {/* Left side: API connection statuses */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-1.5">
          <StatusIndicator status="online" size="sm" />
          <span>FastAPI: <span className="text-neutral-400">{fastApiUrl}</span></span>
        </div>
        <div className="w-[1px] h-3 bg-white/10" />
        <div className="flex items-center gap-1.5">
          <Cpu className="w-3 h-3 text-neutral-500" />
          <span>Model: <span className="text-indigo-400">{activeModel}</span></span>
        </div>
        <div className="w-[1px] h-3 bg-white/10" />
        <div className="flex items-center gap-1.5">
          <Database className="w-3 h-3 text-neutral-500" />
          <span>SQLite: <span className="text-emerald-500">Connected</span></span>
        </div>
      </div>

      {/* Right side: Shortcut tips & System settings link */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-1">
          <Keyboard className="w-3 h-3 text-neutral-600" />
          <span>Keyboard Shortcuts: <kbd className="bg-neutral-900 border border-white/10 px-1 rounded text-neutral-400 text-[9px]">⌘ /</kbd></span>
        </div>
        <div className="w-[1px] h-3 bg-white/10" />
        <div className="flex items-center gap-1.5">
          <Wifi className="w-3.5 h-3.5 text-emerald-500 animate-pulse-slow" />
          <span>Sync Gateway: Online</span>
        </div>
      </div>
    </footer>
  );
}
