"use client";

import React from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Cpu,
  Check,
  Zap
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

export function ModelsView() {
  const { models, activeModel, setActiveModel } = useWorkspace();

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">AI Model Directory</h1>
          <p className="text-xs text-neutral-400 mt-1">Select and configure default inference engines from OpenRouter and local Ollama nodes.</p>
        </div>
      </div>

      {/* Selector List */}
      <div className="space-y-4">
        <h2 className="text-xs font-semibold text-neutral-400 uppercase tracking-wider">
          Available Inference Systems
        </h2>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {models.map((model) => {
            const isSelected = activeModel === model.id;
            
            return (
              <Card
                key={model.id}
                onClick={() => setActiveModel(model.id)}
                className={`p-4 cursor-pointer border transition-all text-left ${
                  isSelected
                    ? "border-indigo-500/30 bg-indigo-600/5 shadow-[0_0_15px_rgba(99,102,241,0.05)]"
                    : "border-white/5"
                }`}
              >
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-3">
                    <div className={`p-2.5 rounded-lg bg-neutral-900 border ${
                      isSelected ? "border-indigo-500/20 text-indigo-400" : "border-white/5 text-neutral-400"
                    }`}>
                      <Cpu className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-1.5">
                        <h3 className="text-xs font-bold text-neutral-200">{model.name}</h3>
                        <span className="text-[8px] font-mono font-semibold px-1.5 py-0.5 rounded bg-neutral-900 border border-white/5 text-neutral-400">
                          {model.provider}
                        </span>
                      </div>
                      <p className="text-[10px] text-neutral-500 mt-1">Context: <span className="font-mono text-neutral-300">{model.contextWindow}</span></p>
                    </div>
                  </div>

                  {/* Radio Indicator */}
                  <div className={`w-5 h-5 rounded-full border flex items-center justify-center transition-all ${
                    isSelected ? "border-indigo-500 bg-indigo-600" : "border-white/20"
                  }`}>
                    {isSelected && <Check className="w-3.5 h-3.5 text-white" />}
                  </div>
                </div>

                <div className="flex items-center justify-between border-t border-white/5 pt-3 mt-3 text-[10px] font-mono text-neutral-500">
                  <div className="flex items-center gap-1">
                    <Zap className="w-3.5 h-3.5 text-amber-500" />
                    <span>Avg Latency: <span className="text-neutral-300">{model.latency}</span></span>
                  </div>
                  
                  <div className="flex items-center gap-1.5">
                    <StatusIndicator status={model.status} size="sm" />
                    <span className={model.status === "online" ? "text-emerald-400" : "text-rose-400"}>
                      {model.status === "online" ? "Online" : "Offline"}
                    </span>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
}
