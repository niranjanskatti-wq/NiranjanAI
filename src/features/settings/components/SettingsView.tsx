"use client";

import React, { useState } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Key,
  Palette,
  Keyboard,
  Save,
  HelpCircle
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export function SettingsView() {
  const {
    apiKeys,
    setApiKeys,
    fastApiUrl,
    setFastApiUrl,
    theme,
    setTheme
  } = useWorkspace();

  const [openRouterKey, setOpenRouterKey] = useState(apiKeys.openRouter);
  const [ollamaHost, setOllamaHost] = useState(apiKeys.ollama);
  const [hermesKey, setHermesKey] = useState(apiKeys.hermes);
  const [fastApi, setFastApi] = useState(fastApiUrl);

  const [saveSuccess, setSaveSuccess] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setApiKeys({
      openRouter: openRouterKey,
      ollama: ollamaHost,
      hermes: hermesKey
    });
    setFastApiUrl(fastApi);
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  const keyboardShortcuts = [
    { keys: "⌘ K", description: "Fuzzy search bar active" },
    { keys: "⌘ Enter", description: "Execute prompt run workflow" },
    { keys: "⌘ B", description: "Toggle left sidebar collapsible state" },
    { keys: "⌘ /", description: "Open system shortcut helper panel" },
    { keys: "ESC", description: "Close active modals and dialogues" }
  ];

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Workspace Preferences</h1>
          <p className="text-xs text-neutral-400 mt-1">Configure global API tokens, theme layouts, and connection adapters.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Settings Form */}
        <form onSubmit={handleSave} className="xl:col-span-2 space-y-6 text-xs text-left">
          {/* API Key section */}
          <Card className="p-5 space-y-4">
            <div className="flex items-center gap-2 border-b border-white/5 pb-2.5 mb-2.5">
              <Key className="w-4 h-4 text-indigo-400" />
              <h2 className="text-sm font-semibold text-neutral-200">API Connection Keys</h2>
            </div>

            <div className="space-y-4">
              <div className="space-y-1">
                <label className="block text-neutral-400 font-semibold">OpenRouter API Secret Token</label>
                <input
                  type="password"
                  value={openRouterKey}
                  onChange={(e) => setOpenRouterKey(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50"
                  placeholder="sk-or-v1-..."
                />
              </div>

              <div className="space-y-1">
                <label className="block text-neutral-400 font-semibold">Ollama Inference Connection Host</label>
                <input
                  type="text"
                  value={ollamaHost}
                  onChange={(e) => setOllamaHost(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50 font-mono"
                  placeholder="http://localhost:11434"
                />
              </div>

              <div className="space-y-1">
                <label className="block text-neutral-400 font-semibold">Hermes Agent Encryption Passkey</label>
                <input
                  type="password"
                  value={hermesKey}
                  onChange={(e) => setHermesKey(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50"
                  placeholder="Passkey"
                />
              </div>

              <div className="space-y-1">
                <label className="block text-neutral-400 font-semibold">FastAPI Local Engine URL</label>
                <input
                  type="text"
                  value={fastApi}
                  onChange={(e) => setFastApi(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-lg p-2.5 text-neutral-200 focus:outline-none focus:border-indigo-500/50 font-mono"
                  placeholder="http://127.0.0.1:8000"
                />
              </div>
            </div>
          </Card>

          {/* Theme appearance panel */}
          <Card className="p-5 space-y-4">
            <div className="flex items-center gap-2 border-b border-white/5 pb-2.5 mb-2.5">
              <Palette className="w-4 h-4 text-indigo-400" />
              <h2 className="text-sm font-semibold text-neutral-200">App Custom Appearance</h2>
            </div>

            <div className="grid grid-cols-3 gap-3">
              {[
                { id: "dark", label: "Obsidian Black", bg: "bg-neutral-950", border: "border-neutral-800" },
                { id: "midnight", label: "Slate Midnight", bg: "bg-slate-950", border: "border-slate-800" },
                { id: "light", label: "Premium Light", bg: "bg-white", border: "border-neutral-200 text-neutral-900" }
              ].map((opt) => {
                const isSelected = theme === opt.id;
                return (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => setTheme(opt.id)}
                    className={`p-3 rounded-lg border flex flex-col justify-between h-20 text-left cursor-pointer transition-all ${opt.bg} ${opt.border} ${
                      isSelected ? "ring-2 ring-indigo-500 border-transparent animate-pulse-slow" : "opacity-80 hover:opacity-100"
                    }`}
                  >
                    <span className="text-[10px] font-bold">{opt.label}</span>
                    <div className="w-4 h-4 rounded-full border border-white/20 bg-indigo-600/30 flex items-center justify-center">
                      {isSelected && <div className="w-2 h-2 rounded-full bg-indigo-500" />}
                    </div>
                  </button>
                );
              })}
            </div>
          </Card>

          {/* Save Action */}
          <div className="flex items-center gap-3 justify-end pt-2">
            {saveSuccess && (
              <span className="text-[10px] text-emerald-400 font-semibold font-mono animate-pulse-slow">
                Configurations Saved Successfully.
              </span>
            )}
            <Button variant="primary" type="submit" className="flex items-center gap-1.5">
              <Save className="w-4 h-4" />
              <span>Save Changes</span>
            </Button>
          </div>
        </form>

        {/* Keyboard Shortcuts Summary Card */}
        <div className="space-y-6 text-left">
          <Card className="p-5 space-y-4">
            <div className="flex items-center gap-2 border-b border-white/5 pb-2.5 mb-2.5">
              <Keyboard className="w-4 h-4 text-indigo-400" />
              <h2 className="text-sm font-semibold text-neutral-200">OS Hotkeys Guide</h2>
            </div>
            
            <div className="space-y-3 font-mono text-[10px]">
              {keyboardShortcuts.map((sc, idx) => (
                <div key={idx} className="flex justify-between items-center py-1 border-b border-white/5">
                  <span className="text-neutral-400">{sc.description}</span>
                  <kbd className="bg-neutral-900 border border-white/10 px-2 py-0.5 rounded text-neutral-200 font-bold select-all">
                    {sc.keys}
                  </kbd>
                </div>
              ))}
            </div>
          </Card>

          {/* Quick Help documentation link mockup */}
          <Card className="p-5 space-y-3">
            <div className="flex items-center gap-2 text-neutral-300">
              <HelpCircle className="w-4 h-4 text-indigo-400" />
              <h3 className="text-xs font-bold text-neutral-200">Local Documentation</h3>
            </div>
            <p className="text-[10px] text-neutral-500 leading-relaxed">
              Read the Niranjan AI SDK Guidelines. Connect custom agents via the Hermes API framework or write custom plugins using the Plugin SDK model adapters.
            </p>
          </Card>
        </div>
      </div>
    </div>
  );
}
