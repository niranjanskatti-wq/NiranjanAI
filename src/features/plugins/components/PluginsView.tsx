"use client";

import React from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Puzzle,
  Settings2,
  Cpu,
  Globe,
  Building,
  Plane,
  Sprout,
  Video
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

export function PluginsView() {
  const { plugins, togglePlugin } = useWorkspace();

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs">
      {/* Header */}
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Plugin Registry</h1>
          <p className="text-xs text-neutral-400 mt-1">Configure active extensions and micro-service integrations.</p>
        </div>
      </div>

      {/* Grid of extension plugins */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {plugins.map((plugin) => {
          let PluginIcon = Puzzle;
          let accentBorder = "border-neutral-800";
          let iconColor = "text-indigo-400";
          
          if (plugin.id === "hermes") {
            PluginIcon = Cpu;
            accentBorder = plugin.enabled ? "border-indigo-500/20 shadow-lg shadow-indigo-600/5" : "";
            iconColor = "text-indigo-400";
          } else if (plugin.id === "ifza") {
            PluginIcon = Building;
            accentBorder = plugin.enabled ? "border-sky-500/20 shadow-lg shadow-sky-600/5" : "";
            iconColor = "text-sky-400";
          } else if (plugin.id === "flights") {
            PluginIcon = Plane;
            accentBorder = plugin.enabled ? "border-teal-500/20 shadow-lg shadow-teal-600/5" : "";
            iconColor = "text-teal-400";
          } else if (plugin.id === "research") {
            PluginIcon = Globe;
            accentBorder = plugin.enabled ? "border-emerald-500/20 shadow-lg shadow-emerald-600/5" : "";
            iconColor = "text-emerald-400";
          } else if (plugin.id === "farm") {
            PluginIcon = Sprout;
            accentBorder = plugin.enabled ? "border-amber-500/20 shadow-lg shadow-amber-600/5" : "";
            iconColor = "text-amber-400";
          } else if (plugin.id === "camera") {
            PluginIcon = Video;
            accentBorder = plugin.enabled ? "border-rose-500/20 shadow-lg shadow-rose-600/5" : "";
            iconColor = "text-rose-400";
          }

          return (
            <Card
              key={plugin.id}
              hoverEffect={true}
              className={`p-5 flex flex-col justify-between h-56 transition-all duration-300 ${accentBorder}`}
            >
              <div className="space-y-3">
                {/* Plugin Top Bar: Icon, Name, Switch */}
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 rounded-lg bg-neutral-900 border border-white/5 text-neutral-300">
                      <PluginIcon className={`w-5 h-5 ${iconColor}`} />
                    </div>
                    <div>
                      <h3 className="text-xs font-bold text-neutral-200">{plugin.name}</h3>
                      <p className="text-[9px] text-neutral-500 font-mono">v{plugin.version} • by {plugin.author}</p>
                    </div>
                  </div>
                  
                  {/* Enable Toggle Switch */}
                  <label className="relative inline-flex items-center cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={plugin.enabled}
                      onChange={() => togglePlugin(plugin.id)}
                      className="sr-only peer"
                    />
                    <div className="w-8 h-4 bg-neutral-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-neutral-400 peer-checked:after:bg-indigo-400 after:border-neutral-300 after:border after:rounded-full after:h-3 after:w-3.5 after:transition-all peer-checked:bg-indigo-600/30"></div>
                  </label>
                </div>

                {/* Description */}
                <p className="text-xs text-neutral-400 leading-relaxed line-clamp-2 h-10 text-left">
                  {plugin.description}
                </p>
              </div>

              {/* Status details / settings action */}
              <div className="flex items-center justify-between border-t border-white/5 pt-3 mt-3 text-[10px]">
                <div className="flex items-center gap-1.5 font-mono text-neutral-500">
                  <span className="text-[9px] uppercase">State:</span>
                  <StatusIndicator status={plugin.enabled ? "online" : "disabled"} size="sm" />
                  <span className={plugin.enabled ? "text-emerald-400" : "text-neutral-500"}>
                    {plugin.enabled ? "Enabled" : "Disabled"}
                  </span>
                </div>
                
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={() => alert(`Settings configured for ${plugin.name}.`)}
                  className="px-2.5 py-1 text-[10px] min-w-0"
                  disabled={!plugin.enabled}
                >
                  <Settings2 className="w-3.5 h-3.5 mr-1" />
                  Configure
                </Button>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
