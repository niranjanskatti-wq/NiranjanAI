"use client";

import React, { useRef } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Sparkles,
  Building,
  Plane,
  Search,
  FileText,
  Sprout,
  Globe,
  Mail,
  Calendar,
  FolderSearch,
  BookOpen,
  Camera,
  Monitor,
  Play,
  Cpu,
  Database,
  Radio,
  Server,
  Workflow
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

export function DashboardView() {
  const {
    prompt,
    setPrompt,
    runPrompt,
    isExecuting,
    activeModel
  } = useWorkspace();

  const promptInputRef = useRef<HTMLTextAreaElement>(null);

  const quickActions = [
    {
      id: "ifza",
      title: "IFZA Activities",
      description: "Query license requirements and fee calculator",
      icon: Building,
      preset: "Help me calculate the setup fee for a commercial license in IFZA Dubai, including 3 visa allocations.",
      color: "text-indigo-400 border-indigo-500/10"
    },
    {
      id: "flights",
      title: "Flight Comparison",
      description: "Analyze direct DXB-LHR July schedules",
      icon: Plane,
      preset: "Find the best direct flights from Dubai (DXB) to London Heathrow (LHR) between July 12 and July 20.",
      color: "text-sky-400 border-sky-500/10"
    },
    {
      id: "research",
      title: "Deep Research",
      description: "Synthesize latest findings on agent workflows",
      icon: Search,
      preset: "Research recent papers on multi-agent reinforcement learning orchestration.",
      color: "text-emerald-400 border-emerald-500/10"
    },
    {
      id: "docs",
      title: "Documents",
      description: "Retrieve corporate structure files",
      icon: FileText,
      preset: "Scan my knowledge base for IFZA corporate registry requirements.",
      color: "text-purple-400 border-purple-500/10"
    },
    {
      id: "farm",
      title: "Farm Monitoring",
      description: "Soil moisture checks & smart irrigation overrides",
      icon: Sprout,
      preset: "Fetch smart farm metrics: soil temperature, moisture level, and irrigation triggers.",
      color: "text-amber-400 border-amber-500/10"
    },
    {
      id: "browser",
      title: "Browser Automation",
      description: "Run automated price tracking workflows",
      icon: Globe,
      preset: "Automate browser login to price-tracker portal and fetch competitor benchmarks.",
      color: "text-cyan-400 border-cyan-500/10"
    },
    {
      id: "email",
      title: "Email Outreach",
      description: "Draft follow-ups with corporate clients",
      icon: Mail,
      preset: "Draft a professional email follow-up regarding the IFZA license approval timeline.",
      color: "text-rose-400 border-rose-500/10"
    },
    {
      id: "calendar",
      title: "Calendar Sync",
      description: "Audit scheduling overlaps for the week",
      icon: Calendar,
      preset: "Summarize my calendar schedule for tomorrow and check for multi-timezone overlaps.",
      color: "text-teal-400 border-teal-500/10"
    },
    {
      id: "filesearch",
      title: "File Search",
      description: "Fuzzy search across local databases",
      icon: FolderSearch,
      preset: "Locate code adapters representing openrouter and ollama services.",
      color: "text-blue-400 border-blue-500/10"
    },
    {
      id: "meeting",
      title: "Meeting Notes",
      description: "Auto-summarize audio and draft action items",
      icon: BookOpen,
      preset: "Create action items list based on latest audio transcripts.",
      color: "text-fuchsia-400 border-fuchsia-500/10"
    },
    {
      id: "camera",
      title: "Camera Monitoring",
      description: "Analyze security video feed activity logs",
      icon: Camera,
      preset: "Check CCTV monitor motion alerts for anomalies in agricultural zones.",
      color: "text-pink-400 border-pink-500/10"
    },
    {
      id: "desktop",
      title: "Desktop Control",
      description: "Trigger macro recordings & system controls",
      icon: Monitor,
      preset: "Execute desktop automation macros to map local workspace configurations.",
      color: "text-violet-400 border-violet-500/10"
    }
  ];

  const systemStatus = [
    { name: "Hermes Gateway", icon: Workflow, provider: "Cloud Core", latency: "14ms", health: "98%" },
    { name: "Ollama Local", icon: Cpu, provider: "Localhost", latency: "8ms", health: "100%" },
    { name: "OpenRouter Hub", icon: Radio, provider: "Edge Proxy", latency: "162ms", health: "97%" },
    { name: "FastAPI Engine", icon: Server, provider: "System Engine", latency: "4ms", health: "100%" },
    { name: "SQLite Database", icon: Database, provider: "Local SQLite", latency: "1ms", health: "100%" },
    { name: "Browser Automation", icon: Globe, provider: "Playwright Helper", latency: "23ms", health: "96%" },
    { name: "Filesystem Host", icon: FolderSearch, provider: "MacOS Sandbox", latency: "2ms", health: "99%" }
  ];

  const handleCardClick = (preset: string) => {
    setPrompt(preset);
    if (promptInputRef.current) {
      promptInputRef.current.focus();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      runPrompt();
    }
  };

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      {/* Welcome Section */}
      <div className="flex justify-between items-end border-b border-white/5 pb-4">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Welcome back, Niranjan</h1>
          <p className="text-xs text-neutral-400 mt-1">What would you like me to do today?</p>
        </div>
        <div className="text-[10px] text-neutral-500 font-mono">
          Model Engine: <span className="text-indigo-400">{activeModel}</span>
        </div>
      </div>

      {/* Main Prompt Box */}
      <Card variant="premium" className="p-4 relative">
        <textarea
          ref={promptInputRef}
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Ask me anything... (⌘ Enter to run)"
          onKeyDown={handleKeyDown}
          className="w-full bg-transparent border-none text-sm text-neutral-100 placeholder-neutral-500 focus:outline-none resize-none h-24 focus-visible:ring-0"
        />
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-white/5">
          <div className="flex items-center gap-1.5 text-xs text-neutral-500">
            <Sparkles className="w-3.5 h-3.5 text-indigo-400" />
            <span>Active model: {activeModel}</span>
          </div>
          <Button
            variant="glowing-run"
            size="md"
            onClick={() => runPrompt()}
            isLoading={isExecuting}
            disabled={!prompt.trim()}
            className="flex items-center gap-2"
          >
            <Play className={`w-3.5 h-3.5 fill-current ${isExecuting ? "animate-pulse" : ""}`} />
            <span>Run Pipeline</span>
          </Button>
        </div>
      </Card>

      {/* Quick Actions Grid */}
      <div className="space-y-3">
        <h2 className="text-xs font-semibold text-neutral-400 uppercase tracking-wider">
          Quick Action Matrix
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {quickActions.map((action) => {
            const IconComponent = action.icon;
            return (
              <Card
                key={action.id}
                onClick={() => handleCardClick(action.preset)}
                className="p-4 cursor-pointer flex flex-col justify-between h-32"
              >
                <div className="flex justify-between items-start">
                  <div className={`p-2 rounded-lg bg-neutral-900 border ${action.color}`}>
                    <IconComponent className="w-4 h-4" />
                  </div>
                </div>
                <div className="mt-3">
                  <h3 className="text-xs font-bold text-neutral-200">{action.title}</h3>
                  <p className="text-[10px] text-neutral-500 mt-1 line-clamp-2 leading-relaxed text-left">
                    {action.description}
                  </p>
                </div>
              </Card>
            );
          })}
        </div>
      </div>

      {/* System Status Section */}
      <div className="space-y-3">
        <h2 className="text-xs font-semibold text-neutral-400 uppercase tracking-wider">
          System Node Registry
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {systemStatus.map((node, idx) => {
            const Icon = node.icon;
            return (
              <Card key={idx} hoverEffect={false} className="p-3 bg-neutral-950/20 border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-1.5 rounded-lg bg-white/5 border border-white/5 text-neutral-400">
                    <Icon className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold text-neutral-200">{node.name}</h4>
                    <p className="text-[9px] text-neutral-500 mt-0.5">{node.provider}</p>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <StatusIndicator status="online" size="sm" />
                  <span className="text-[9px] font-mono text-neutral-500">
                    {node.latency} | H: {node.health}
                  </span>
                </div>
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
}
