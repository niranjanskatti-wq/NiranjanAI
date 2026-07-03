"use client";

import React from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  LayoutDashboard,
  MessageSquare,
  Search,
  Globe,
  Terminal,
  PlaySquare,
  FileText,
  Puzzle,
  Cpu,
  Plane,
  Building,
  Sprout,
  Settings,
  ChevronLeft,
  ChevronRight,
  User
} from "lucide-react";

export function Sidebar() {
  const {
    activeView,
    setActiveView,
    sidebarCollapsed,
    setSidebarCollapsed,
    activeWorkspace,
    setActiveWorkspace
  } = useWorkspace();

  const navigationItems = [
    { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
    { id: "chat", label: "AI Chat", icon: MessageSquare },
    { id: "research", label: "Research", icon: Search },
    { id: "browser", label: "Browser", icon: Globe },
    { id: "automation", label: "Automation", icon: Terminal },
    { id: "tasks", label: "Tasks", icon: PlaySquare },
    { id: "documents", label: "Documents", icon: FileText },
    { id: "plugins", label: "Plugins", icon: Puzzle },
    { id: "models", label: "Models", icon: Cpu },
    { id: "flights", label: "Flights", icon: Plane },
    { id: "ifza", label: "IFZA", icon: Building },
    { id: "farm", label: "Farm", icon: Sprout },
    { id: "settings", label: "Settings", icon: Settings }
  ] as const;

  const workspaces = ["Main OS", "Dubai Setup", "Personal Lab"] as const;

  return (
    <div
      className={`relative flex flex-col h-full bg-neutral-950/90 border-r border-white/5 transition-all duration-300 ${
        sidebarCollapsed ? "w-16" : "w-64"
      }`}
    >
      {/* Sidebar Header / Logo */}
      <div className="flex items-center justify-between p-4 border-b border-white/5 h-16">
        {!sidebarCollapsed && (
          <div className="flex items-center gap-2 font-bold text-white text-base tracking-wide select-none">
            <span className="text-xl">🤖</span>
            <span>Niranjan AI</span>
          </div>
        )}
        {sidebarCollapsed && (
          <div className="text-xl text-center w-full select-none">🤖</div>
        )}
        
        {/* Toggle Collapse Button */}
        <button
          onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
          className="absolute -right-3 top-5 bg-neutral-900 border border-white/10 hover:bg-neutral-800 text-neutral-400 hover:text-white rounded-full p-0.5 cursor-pointer z-10 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/50"
        >
          {sidebarCollapsed ? (
            <ChevronRight className="w-3.5 h-3.5" />
          ) : (
            <ChevronLeft className="w-3.5 h-3.5" />
          )}
        </button>
      </div>

      {/* Workspace Selector */}
      {!sidebarCollapsed && (
        <div className="p-3">
          <label className="text-[10px] font-semibold text-neutral-500 uppercase tracking-widest px-2 mb-1 block">
            Active Workspace
          </label>
          <select
            value={activeWorkspace}
            onChange={(e) => setActiveWorkspace(e.target.value)}
            className="w-full bg-white/5 border border-white/10 text-neutral-200 text-xs rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-indigo-500/50 cursor-pointer"
          >
            {workspaces.map((ws) => (
              <option key={ws} value={ws} className="bg-neutral-900 text-neutral-200">
                {ws}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Navigation List */}
      <div className="flex-1 overflow-y-auto px-2 py-3 space-y-1">
        {!sidebarCollapsed && (
          <p className="text-[10px] font-semibold text-neutral-500 uppercase tracking-widest px-2 mb-2 select-none">
            Navigation
          </p>
        )}
        {navigationItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeView === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveView(item.id)}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 group relative cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/50 ${
                isActive
                  ? "bg-indigo-600/20 text-white border-l-2 border-indigo-500"
                  : "text-neutral-400 hover:text-white hover:bg-white/5"
              }`}
              title={sidebarCollapsed ? item.label : undefined}
            >
              <Icon className={`w-4 h-4 shrink-0 transition-transform duration-200 group-hover:scale-110 ${isActive ? "text-indigo-400" : "text-neutral-400 group-hover:text-neutral-200"}`} />
              {!sidebarCollapsed && <span>{item.label}</span>}
              
              {/* Tooltip for Collapsed view */}
              {sidebarCollapsed && (
                <div className="absolute left-full ml-2 px-2.5 py-1 bg-neutral-900 border border-white/10 text-white text-xs rounded-md opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-50 shadow-xl">
                  {item.label}
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* Profile Card */}
      <div className="p-3 border-t border-white/5 bg-black/20">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-indigo-600/30 border border-indigo-500/30 flex items-center justify-center shrink-0">
            <User className="w-4 h-4 text-indigo-400" />
          </div>
          {!sidebarCollapsed && (
            <div className="flex-1 min-w-0 text-left">
              <p className="text-xs font-semibold text-neutral-200 truncate">Niranjan</p>
              <p className="text-[10px] text-neutral-500 truncate">niranjan@ai-os.com</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
