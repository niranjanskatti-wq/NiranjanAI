"use client";

import React, { useState, useEffect } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Search,
  Bell,
  Sun,
  Moon,
  Sparkles,
  Clock,
  Laptop,
  Palette
} from "lucide-react";
import { Button } from "@/components/ui/Button";

export function Header() {
  const {
    activeWorkspace,
    activeModel,
    setActiveModel,
    theme,
    setTheme,
    models
  } = useWorkspace();

  const [mounted, setMounted] = useState(false);
  const [timeString, setTimeString] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [showThemeMenu, setShowThemeMenu] = useState(false);

  useEffect(() => {
    setMounted(true);
    const updateTime = () => {
      const now = new Date();
      setTimeString(
        now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="flex items-center justify-between px-6 bg-neutral-950/60 border-b border-white/5 h-16 backdrop-blur-md shrink-0">
      {/* Left side: Workspace & Search */}
      <div className="flex items-center gap-6 flex-1 max-w-xl">
        <div className="flex items-center gap-2 select-none">
          <span className="text-xs font-semibold px-2.5 py-1 rounded bg-neutral-900 border border-white/5 text-neutral-300">
            {activeWorkspace}
          </span>
        </div>

        {/* Global Search Bar (Raycast inspired) */}
        <div className="relative w-full group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-500 group-focus-within:text-indigo-400 transition-colors" />
          <input
            type="text"
            placeholder="Search tasks, documents, plugins... (⌘ K)"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-white/5 border border-white/10 rounded-lg pl-9 pr-4 py-1.5 text-xs text-neutral-200 placeholder-neutral-500 focus:outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/50 focus:bg-neutral-900/50 transition-all"
            onKeyDown={(e) => {
              if (e.key === "Enter" && searchQuery.trim()) {
                alert(`Search query entered: "${searchQuery}"`);
                setSearchQuery("");
              }
            }}
          />
        </div>
      </div>

      {/* Right side: AI model selector, Clock, Notifications, Theme, User */}
      <div className="flex items-center gap-4 shrink-0">
        {/* Model Selector Dropdown */}
        <div className="flex items-center gap-1.5 bg-white/5 border border-white/10 rounded-lg px-2.5 py-1">
          <Sparkles className="w-3.5 h-3.5 text-indigo-400" />
          <select
            value={activeModel}
            onChange={(e) => setActiveModel(e.target.value)}
            className="bg-transparent text-neutral-200 text-xs font-medium focus:outline-none cursor-pointer"
          >
            {models.map((m) => (
              <option key={m.id} value={m.id} className="bg-neutral-900 text-neutral-200">
                {m.name} ({m.provider})
              </option>
            ))}
          </select>
        </div>

        {/* Local Clock */}
        <div className="flex items-center gap-1.5 px-3 py-1 bg-white/5 border border-white/10 rounded-lg text-neutral-400 text-xs font-mono select-none">
          <Clock className="w-3.5 h-3.5 text-neutral-500" />
          <span>{mounted ? timeString : "--:--:--"}</span>
        </div>

        {/* Theme Dropdown Toggle */}
        <div className="relative">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setShowThemeMenu(!showThemeMenu)}
            className="p-1.5 min-w-0"
            title="Switch Theme"
          >
            <Palette className="w-4 h-4 text-neutral-400 hover:text-white" />
          </Button>

          {showThemeMenu && (
            <div className="absolute right-0 mt-2 w-36 rounded-lg border border-white/10 bg-neutral-950 p-1.5 shadow-xl z-50">
              {[
                { id: "dark", label: "Obsidian", icon: Moon },
                { id: "midnight", label: "Midnight", icon: Laptop },
                { id: "light", label: "Light", icon: Sun }
              ].map((themeOpt) => {
                const ItemIcon = themeOpt.icon;
                return (
                  <button
                    key={themeOpt.id}
                    onClick={() => {
                      setTheme(themeOpt.id);
                      setShowThemeMenu(false);
                    }}
                    className={`w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md text-xs font-medium text-left transition-colors cursor-pointer ${
                      theme === themeOpt.id
                        ? "bg-indigo-600/20 text-indigo-300"
                        : "text-neutral-400 hover:text-white hover:bg-white/5"
                    }`}
                  >
                    <ItemIcon className="w-3.5 h-3.5" />
                    <span>{themeOpt.label}</span>
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* Notifications */}
        <Button variant="ghost" size="sm" className="p-1.5 min-w-0" title="Notifications">
          <Bell className="w-4 h-4 text-neutral-400 hover:text-white" />
        </Button>
      </div>
    </header>
  );
}
