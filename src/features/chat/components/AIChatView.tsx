"use client";

import React, { useState, useRef, useEffect } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Send,
  Paperclip,
  Image as ImageIcon,
  ChevronRight,
  Pin,
  Search,
  MessageSquare,
  Copy,
  Check,
  Terminal,
  Sparkles
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export function AIChatView() {
  const { chatMessages, sendChatMessage, activeModel } = useWorkspace();
  const [inputText, setInputText] = useState("");
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");

  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (chatEndRef.current) {
      chatEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [chatMessages]);

  const handleSend = () => {
    if (!inputText.trim()) return;
    sendChatMessage(inputText);
    setInputText("");
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const suggestedPrompts = [
    "Check IFZA business license fee schedules.",
    "Draft Python code to query flight latencies.",
    "Scrape farm sensor moisture analytics.",
    "Verify local Ollama host endpoints."
  ];

  const sidebarChats = [
    { id: "1", title: "IFZA Freezone Setup Setup Fee Audit", date: "Today", pinned: true },
    { id: "2", title: "Flight Comparison DXB to LHR", date: "Yesterday", pinned: true },
    { id: "3", title: "AgriTech Moisture Node Calibration", date: "2 days ago", pinned: false },
    { id: "4", title: "Hermes Multimodal Intent Routing", date: "June 28", pinned: false }
  ];

  return (
    <div className="flex-1 flex h-full overflow-hidden">
      {/* Sidebar: Conversation Logs */}
      <div className="w-56 bg-neutral-950/20 border-r border-white/5 flex flex-col shrink-0 h-full">
        <div className="p-3 border-b border-white/5 space-y-2">
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-neutral-500" />
            <input
              type="text"
              placeholder="Search chats..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-white/5 border border-white/10 rounded-md pl-8 pr-3 py-1 text-xs text-neutral-200 placeholder-neutral-500 focus:outline-none focus:border-indigo-500/50"
            />
          </div>
        </div>

        {/* Pinned & Recent Logs */}
        <div className="flex-1 overflow-y-auto p-2 space-y-4">
          <div>
            <span className="text-[9px] font-semibold text-neutral-500 uppercase tracking-widest px-2 block mb-1">
              Pinned
            </span>
            {sidebarChats
              .filter((c) => c.pinned && c.title.toLowerCase().includes(searchQuery.toLowerCase()))
              .map((chat) => (
                <button
                  key={chat.id}
                  className="w-full text-left px-2.5 py-1.5 rounded-md text-xs text-neutral-300 hover:text-white hover:bg-white/5 flex items-center justify-between group cursor-pointer focus-visible:ring-1 focus-visible:ring-indigo-500/50 outline-none"
                >
                  <span className="truncate flex items-center gap-1.5">
                    <MessageSquare className="w-3 h-3 text-indigo-400 shrink-0" />
                    {chat.title}
                  </span>
                  <Pin className="w-2.5 h-2.5 text-indigo-400 shrink-0" />
                </button>
              ))}
          </div>

          <div>
            <span className="text-[9px] font-semibold text-neutral-500 uppercase tracking-widest px-2 block mb-1">
              Recent
            </span>
            {sidebarChats
              .filter((c) => !c.pinned && c.title.toLowerCase().includes(searchQuery.toLowerCase()))
              .map((chat) => (
                <button
                  key={chat.id}
                  className="w-full text-left px-2.5 py-1.5 rounded-md text-xs text-neutral-400 hover:text-white hover:bg-white/5 flex items-center gap-1.5 cursor-pointer focus-visible:ring-1 focus-visible:ring-indigo-500/50 outline-none"
                >
                  <MessageSquare className="w-3 h-3 text-neutral-500 shrink-0" />
                  <span className="truncate">{chat.title}</span>
                </button>
              ))}
          </div>
        </div>
      </div>

      {/* Main Chat Interface */}
      <div className="flex-1 flex flex-col h-full bg-neutral-950/10">
        {/* Active Session Bar */}
        <div className="px-6 py-3 border-b border-white/5 flex justify-between items-center bg-neutral-950/20 shrink-0">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-indigo-400" />
            <span className="text-xs font-semibold text-neutral-200">Active Chat Pipeline</span>
          </div>
          <span className="text-[10px] text-neutral-500 font-mono bg-neutral-900 border border-white/5 px-2 py-0.5 rounded">
            Agent: {activeModel}
          </span>
        </div>

        {/* Message Stream */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {chatMessages.map((msg) => (
            <div
              key={msg.id}
              className={`flex gap-4 max-w-3xl ${msg.sender === "user" ? "ml-auto flex-row-reverse" : "mr-auto"}`}
            >
              {/* Avatar indicator */}
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border shrink-0 ${
                  msg.sender === "user"
                    ? "bg-indigo-600/20 border-indigo-500/30 text-indigo-300"
                    : "bg-white/5 border-white/10 text-neutral-300"
                }`}
              >
                {msg.sender === "user" ? "N" : "🤖"}
              </div>

              {/* Message text bubble */}
              <div className="space-y-2 flex-1">
                <div
                  className={`p-4 rounded-xl border text-sm leading-relaxed ${
                    msg.sender === "user"
                      ? "bg-indigo-600/10 border-indigo-500/20 text-indigo-100"
                      : "bg-white/5 border-white/10 text-neutral-200"
                  }`}
                >
                  <p className="whitespace-pre-wrap">{msg.text}</p>

                  {/* Rendering Code Blocks */}
                  {msg.codeBlock && (
                    <div className="mt-4 rounded-lg overflow-hidden border border-white/10 bg-black/90 font-mono text-xs text-neutral-300 shadow-inner">
                      <div className="flex items-center justify-between px-3 py-1.5 bg-neutral-950 border-b border-white/5">
                        <span className="text-[10px] text-neutral-500 uppercase font-semibold">
                          {msg.codeLanguage || "code"}
                        </span>
                        <button
                          onClick={() => copyToClipboard(msg.codeBlock || "", msg.id)}
                          className="flex items-center gap-1 text-[10px] text-neutral-400 hover:text-white cursor-pointer"
                        >
                          {copiedId === msg.id ? (
                            <>
                              <Check className="w-3 h-3 text-emerald-400" />
                              <span className="text-emerald-400">Copied!</span>
                            </>
                          ) : (
                            <>
                              <Copy className="w-3 h-3" />
                              <span>Copy</span>
                            </>
                          )}
                        </button>
                      </div>
                      <pre className="p-3 overflow-x-auto">
                        <code>{msg.codeBlock}</code>
                      </pre>
                    </div>
                  )}
                </div>
                <div className={`text-[9px] text-neutral-500 font-mono ${msg.sender === "user" ? "text-right" : "text-left"}`}>
                  {msg.timestamp}
                </div>
              </div>
            </div>
          ))}
          <div ref={chatEndRef} />
        </div>

        {/* Dynamic Suggested Prompts */}
        {chatMessages.length === 1 && (
          <div className="px-6 py-2 flex flex-wrap gap-2 max-w-3xl">
            {suggestedPrompts.map((p, idx) => (
              <button
                key={idx}
                onClick={() => setInputText(p)}
                className="text-xs bg-white/5 border border-white/5 rounded-full px-3 py-1 text-neutral-400 hover:text-white hover:border-indigo-500/30 transition-all flex items-center gap-1 cursor-pointer focus-visible:ring-1 focus-visible:ring-indigo-500/50 outline-none"
              >
                <span>{p}</span>
                <ChevronRight className="w-3 h-3 text-neutral-600" />
              </button>
            ))}
          </div>
        )}

        {/* Chat Control Input */}
        <div className="p-4 border-t border-white/5 bg-neutral-950/20 shrink-0">
          <div className="max-w-3xl mx-auto relative flex items-center bg-white/5 border border-white/10 rounded-xl px-4 py-2 focus-within:border-indigo-500/50 focus-within:ring-1 focus-within:ring-indigo-500/50 transition-all">
            {/* Attachments */}
            <Button
              variant="ghost"
              size="sm"
              className="p-1.5 min-w-0"
              title="Attach document/image"
              onClick={() => alert("Simulating document scanner portal upload.")}
            >
              <Paperclip className="w-4 h-4 text-neutral-500 hover:text-neutral-300" />
            </Button>
            
            <input
              type="text"
              placeholder="Ask Niranjan AI anything..."
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSend()}
              className="flex-1 bg-transparent border-none outline-none text-sm text-neutral-200 placeholder-neutral-500 px-3 py-1 focus:ring-0"
            />
            
            <Button
              variant="primary"
              size="sm"
              onClick={handleSend}
              disabled={!inputText.trim()}
              className="p-1.5 min-w-0 rounded-lg"
            >
              <Send className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
