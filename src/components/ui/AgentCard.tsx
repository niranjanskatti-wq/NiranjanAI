import React from "react";
import { Cpu, Heart, CheckCircle2, ShieldAlert } from "lucide-react";
import { Card } from "./Card";
import { StatusIndicator } from "./StatusIndicator";
import { Agent } from "../../lib/api";

interface AgentCardProps {
  agent: Agent;
  onRunDiagnostic?: () => void;
}

export function AgentCard({ agent, onRunDiagnostic }: AgentCardProps) {
  return (
    <Card hoverEffect={true} className="p-4 flex flex-col justify-between h-64 border-white/5 bg-neutral-950/20">
      <div className="space-y-3">
        {/* Header: Name, Status, Model */}
        <div className="flex justify-between items-start">
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/10">
              <Cpu className="w-4 h-4" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-neutral-200">{agent.name}</h4>
              <span className="text-[8px] font-mono text-neutral-500">Model: {agent.modelUsed}</span>
            </div>
          </div>
          <StatusIndicator status={agent.status} size="sm" showText={true} />
        </div>

        {/* Description */}
        <p className="text-[11px] text-neutral-400 leading-relaxed line-clamp-2">
          {agent.description}
        </p>

        {/* Capabilities badges */}
        <div className="flex flex-wrap gap-1">
          {agent.capabilities.map((cap) => (
            <span
              key={cap}
              className="text-[8px] font-mono font-semibold px-2 py-0.5 rounded-full bg-neutral-900 border border-white/5 text-neutral-400"
            >
              {cap}
            </span>
          ))}
        </div>
      </div>

      {/* Diagnostics / Telemetry */}
      <div className="border-t border-white/5 pt-3 mt-3 space-y-2">
        <div className="flex items-center justify-between text-[9px] font-mono text-neutral-500">
          <div className="flex items-center gap-1">
            <Heart className="w-3.5 h-3.5 text-rose-500" />
            <span>Health index: <span className="text-neutral-300">{agent.health}%</span></span>
          </div>
          <span>Last active: {agent.lastActivity}</span>
        </div>

        {/* Health progress bar */}
        <div className="w-full h-1 bg-neutral-900 rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-300 ${
              agent.health > 90 ? "bg-emerald-500" : agent.health > 70 ? "bg-amber-500" : "bg-rose-500"
            }`}
            style={{ width: `${agent.health}%` }}
          />
        </div>
      </div>
    </Card>
  );
}
