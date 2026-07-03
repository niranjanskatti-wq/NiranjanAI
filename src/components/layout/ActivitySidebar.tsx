"use client";

import React, { useEffect, useRef } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Activity,
  PlayCircle,
  CheckCircle2,
  AlertCircle,
  Trash2,
  Terminal as TerminalIcon,
  RefreshCcw
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export function ActivitySidebar() {
  const {
    tasks,
    terminalLogs,
    isExecuting,
    clearLogs
  } = useWorkspace();

  const terminalEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll log viewport when new logs arrive
  useEffect(() => {
    if (terminalEndRef.current) {
      terminalEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [terminalLogs]);

  return (
    <aside className="w-80 h-full bg-neutral-950/40 border-l border-white/5 flex flex-col backdrop-blur-md shrink-0">
      {/* Sidebar Header */}
      <div className="flex items-center justify-between p-4 border-b border-white/5 h-16 bg-neutral-950/20 shrink-0 select-none">
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-indigo-400" />
          <h2 className="text-sm font-semibold text-neutral-200">AI Activity Feed</h2>
        </div>
        {isExecuting && (
          <span className="flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            <RefreshCcw className="w-2.5 h-2.5 animate-spin" />
            Executing
          </span>
        )}
      </div>

      {/* Recent Tasks List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        <h3 className="text-xs font-semibold text-neutral-500 uppercase tracking-wider mb-2 select-none text-left">
          Recent Task Sync
        </h3>
        
        {tasks.slice(0, 5).map((task) => {
          let StatusIcon = PlayCircle;
          let colorClass = "text-neutral-400";
          let bgClass = "bg-neutral-500/10";
          
          if (task.status === "completed") {
            StatusIcon = CheckCircle2;
            colorClass = "text-emerald-500";
            bgClass = "bg-emerald-500/10";
          } else if (task.status === "failed") {
            StatusIcon = AlertCircle;
            colorClass = "text-rose-500";
            bgClass = "bg-rose-500/10";
          } else if (task.status === "running") {
            StatusIcon = PlayCircle;
            colorClass = "text-amber-500";
            bgClass = "bg-amber-500/10";
          }

          return (
            <div
              key={task.id}
              className="p-3 bg-white/5 border border-white/5 rounded-lg hover:border-white/10 transition-all flex items-start gap-3 text-left"
            >
              <div className={`p-1.5 rounded-md ${bgClass} ${colorClass} shrink-0`}>
                <StatusIcon className="w-4 h-4" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start">
                  <p className="text-xs font-semibold text-neutral-200 truncate">{task.title}</p>
                </div>
                <div className="flex justify-between items-center mt-1">
                  <span className="text-[10px] text-neutral-500">{task.agentUsed}</span>
                  <span className="text-[10px] text-neutral-400 font-mono">{task.timestamp}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Terminal View Console */}
      <div className="h-64 border-t border-white/5 flex flex-col bg-black/90">
        <div className="flex items-center justify-between px-3 py-2 bg-neutral-950 border-b border-white/5 shrink-0 select-none">
          <div className="flex items-center gap-1.5 text-xs text-neutral-400 font-mono">
            <TerminalIcon className="w-3.5 h-3.5 text-neutral-500" />
            <span>Agent Console Logs</span>
          </div>
          <Button variant="ghost" size="sm" onClick={clearLogs} className="p-1 min-w-0" title="Clear Console">
            <Trash2 className="w-3.5 h-3.5 text-neutral-500 hover:text-rose-400" />
          </Button>
        </div>
        
        {/* Monospaced Log Area */}
        <div className="flex-1 overflow-y-auto p-3 font-mono text-[10px] leading-relaxed space-y-1 select-text text-left">
          {terminalLogs.map((log, idx) => {
            const isError = log.includes("[ERROR]");
            const isSuccess = log.includes("completed") || log.includes("Success");
            
            let logColor = "text-neutral-400";
            if (isError) logColor = "text-rose-400";
            else if (isSuccess) logColor = "text-emerald-400";
            
            return (
              <div key={idx} className={logColor}>
                {log}
              </div>
            );
          })}
          {isExecuting && (
            <div className="text-indigo-400 flex items-center gap-1">
              <span>&gt; Processing agent request</span>
              <span className="inline-block w-1.5 h-3 bg-indigo-400 animate-cursor-blink border-l"></span>
            </div>
          )}
          <div ref={terminalEndRef} />
        </div>
      </div>
    </aside>
  );
}
