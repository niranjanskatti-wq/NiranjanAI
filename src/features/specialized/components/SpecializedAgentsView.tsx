"use client";

import React, { useState } from "react";
import {
  Search,
  Globe,
  Plane,
  Building,
  Sprout,
  ArrowRight,
  TrendingDown,
  Droplet
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

// ==========================================
// 1. RESEARCH AGENT VIEW
// ==========================================
export function ResearchView() {
  const [query, setQuery] = useState("Multi-agent framework architectures");
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Deep Research Hub</h1>
          <p className="text-xs text-neutral-400 mt-1">Cross-reference web indices and compile technical summaries.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-4 flex gap-3 items-center">
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="flex-1 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-neutral-200 focus:outline-none"
            />
            <Button variant="primary" className="flex items-center gap-1">
              <Search className="w-3.5 h-3.5" />
              <span>Query Index</span>
            </Button>
          </Card>
          <Card className="p-5 space-y-4">
            <h3 className="text-xs font-bold text-neutral-200">Latest Compiled Syntheses</h3>
            <div className="space-y-4 border-l border-white/5 pl-4 ml-2">
              <div className="relative">
                <div className="absolute -left-[21px] top-1.5 w-2 h-2 rounded-full bg-indigo-500 ring-4 ring-indigo-500/10" />
                <h4 className="font-semibold text-neutral-300">Reinforcement Learning Orchestration</h4>
                <p className="text-[11px] text-neutral-500 mt-1 leading-relaxed">
                  Synthesized 14 articles from ArXiv and IEEE. Found model routing latencies decrease by 18% when adopting distributed token buffers. Citations appended.
                </p>
              </div>
              <div className="relative">
                <div className="absolute -left-[21px] top-1.5 w-2 h-2 rounded-full bg-indigo-500 ring-4 ring-indigo-500/10" />
                <h4 className="font-semibold text-neutral-300">Neuro-symbolic Reasoning Models</h4>
                <p className="text-[11px] text-neutral-500 mt-1 leading-relaxed">
                  Scraped 8 academic sites. Summary highlights hybrid symbolic code mappings.
                </p>
              </div>
            </div>
          </Card>
        </div>
        <Card className="p-4 space-y-3 h-fit">
          <h3 className="text-xs font-bold text-neutral-200">Research Parameters</h3>
          <div className="space-y-3 font-mono text-[10px] text-neutral-400">
            <div className="flex justify-between">
              <span>Primary Engine:</span>
              <span className="text-neutral-200">Gemini 1.5 Pro</span>
            </div>
            <div className="flex justify-between">
              <span>Max Scraped Pages:</span>
              <span className="text-neutral-200">50 per query</span>
            </div>
            <div className="flex justify-between">
              <span>Database Vector Index:</span>
              <span className="text-emerald-400">Online</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==========================================
// 2. BROWSER AUTOMATION VIEW
// ==========================================
export function BrowserView() {
  const [url, setUrl] = useState("https://portal.dubai.ae");
  const logs = [
    "[16:45:01] Browser session established: Chromium-headless.",
    "[16:45:03] Loaded URL: https://portal.dubai.ae",
    "[16:45:05] Bypassed security checkpoints successfully.",
    "[16:45:08] Awaiting manual action instructions..."
  ];
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Browser Playwright Screen</h1>
          <p className="text-xs text-neutral-400 mt-1">Direct remote headless Chromium controls for automated session pipelines.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-4 flex gap-3 items-center">
            <Globe className="w-4 h-4 text-indigo-400" />
            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="flex-1 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-neutral-200 focus:outline-none"
            />
            <Button variant="primary" className="flex items-center gap-1">
              <ArrowRight className="w-3.5 h-3.5" />
              <span>Navigate</span>
            </Button>
          </Card>
          <Card className="aspect-video bg-neutral-900 border-white/5 rounded-xl flex items-center justify-center relative overflow-hidden group">
            {/* Mock website screenshot frame */}
            <div className="absolute inset-0 bg-gradient-to-tr from-neutral-950 to-neutral-900 flex flex-col p-4 justify-between">
              <div className="flex justify-between items-center">
                <span className="text-[10px] text-indigo-400 font-mono">REMOTE BROWSER FRAME</span>
                <span className="flex items-center gap-1.5"><StatusIndicator status="online" size="sm" /> Live Feed</span>
              </div>
              <div className="text-center font-semibold text-neutral-500">
                Mock screen view of portal.dubai.ae
              </div>
              <div className="text-[10px] text-neutral-600 font-mono">
                Click inside canvas to trigger click actions
              </div>
            </div>
          </Card>
        </div>
        <Card className="p-4 flex flex-col bg-black/90 font-mono text-[10px] text-green-400 h-96">
          <div className="border-b border-white/10 pb-2 mb-2 text-neutral-500 font-bold">
            PLAYWRIGHT LOGS
          </div>
          <div className="flex-1 overflow-y-auto space-y-1">
            {logs.map((log, i) => (
              <div key={i}>{log}</div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==========================================
// 3. AUTOMATION SCRIPTS VIEW
// ==========================================
export function AutomationView() {
  const macros = [
    { title: "Daily Price Benchmarking", cron: "0 0 * * *", active: true },
    { title: "Monthly License Tax Filings", cron: "0 9 1 * *", active: false },
    { title: "Farm moisture alerts", cron: "*/15 * * * *", active: true }
  ];
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Automation Engine</h1>
          <p className="text-xs text-neutral-400 mt-1">Schedule agent tasks or script actions with custom cron pipelines.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-5 space-y-3">
            <h3 className="text-xs font-bold text-neutral-200">Scheduled Routines</h3>
            <div className="space-y-3">
              {macros.map((macro, idx) => (
                <div key={idx} className="flex justify-between items-center p-3 bg-white/5 border border-white/5 rounded-lg">
                  <div>
                    <h4 className="font-semibold text-neutral-200">{macro.title}</h4>
                    <p className="text-[9px] text-neutral-500 font-mono mt-0.5">Cron: {macro.cron}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`text-[10px] font-semibold ${macro.active ? "text-indigo-400" : "text-neutral-500"}`}>
                      {macro.active ? "Active" : "Paused"}
                    </span>
                    <Button variant="secondary" size="sm" className="px-2 py-0.5 text-[10px] min-w-0">
                      Trigger
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
        <Card className="p-4 space-y-3 h-fit">
          <h3 className="text-xs font-bold text-neutral-200">Engine Analytics</h3>
          <div className="space-y-3 font-mono text-[10px] text-neutral-400">
            <div className="flex justify-between">
              <span>Jobs Run today:</span>
              <span className="text-neutral-200">14 completed</span>
            </div>
            <div className="flex justify-between">
              <span>Next trigger:</span>
              <span className="text-indigo-400">in 4 mins</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==========================================
// 4. FLIGHTS AGENT VIEW
// ==========================================
export function FlightsView() {
  const travelOptions = [
    { airline: "Emirates", code: "EK-001", dept: "08:30 DXB", arr: "13:00 LHR", price: "$850", status: "Optimal" },
    { airline: "British Airways", code: "BA-108", dept: "10:15 DXB", arr: "14:50 LHR", price: "$910", status: "Fair" },
    { airline: "Gulf Air", code: "GF-502", dept: "12:00 DXB (1 stop)", arr: "18:30 LHR", price: "$670", status: "Budget" }
  ];
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Flight booking Hub</h1>
          <p className="text-xs text-neutral-400 mt-1">Queries DXB to LHR fare comparisons, calendars, and optimization routes.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-5 space-y-3">
            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-neutral-200">DXB → LHR Schedule comparison</h3>
              <div className="flex items-center gap-1 text-[10px] text-emerald-400">
                <TrendingDown className="w-3.5 h-3.5 animate-pulse" />
                <span>Price Trend: Decreasing</span>
              </div>
            </div>
            <table className="w-full text-left font-mono text-[10px]">
              <thead>
                <tr className="border-b border-white/5 text-neutral-500 uppercase">
                  <th className="py-2">Airline</th>
                  <th className="py-2">Route</th>
                  <th className="py-2 text-right">Fare</th>
                  <th className="py-2 text-right">Assessment</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-neutral-300">
                {travelOptions.map((opt, i) => (
                  <tr key={i} className="hover:bg-white/5">
                    <td className="py-2 font-bold text-neutral-200">{opt.airline} ({opt.code})</td>
                    <td className="py-2">{opt.dept} → {opt.arr}</td>
                    <td className="py-2 text-right font-bold text-neutral-200">{opt.price}</td>
                    <td className="py-2 text-right text-indigo-400">{opt.status}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        </div>
        <Card className="p-4 space-y-3 h-fit">
          <h3 className="text-xs font-bold text-neutral-200">Agent Configuration</h3>
          <div className="space-y-3 font-mono text-[10px] text-neutral-400">
            <div className="flex justify-between">
              <span>Primary Engine:</span>
              <span className="text-neutral-200">GPT-4o API</span>
            </div>
            <div className="flex justify-between">
              <span>Daily price checks:</span>
              <span className="text-emerald-400">Enabled</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==========================================
// 5. IFZA AGENT VIEW
// ==========================================
export function IFZAView() {
  const steps = [
    { title: "Select Company Structure", status: "completed", desc: "Single shareholder or corporate setup selections." },
    { title: "Visa Quota allocation", status: "running", desc: "Selecting number of investor/employee visas needed." },
    { title: "Register trade name", status: "queued", desc: "Validating company name schemas with IFZA registry." }
  ];
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">IFZA Licensing Assistant</h1>
          <p className="text-xs text-neutral-400 mt-1">Dubai Freezone corporate structure setup metrics and visa management.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <Card className="p-5 space-y-3">
            <h3 className="text-xs font-bold text-neutral-200">Corporate Setup Progress</h3>
            <div className="space-y-4">
              {steps.map((step, i) => (
                <div key={i} className="flex gap-3">
                  <div className="pt-0.5">
                    <StatusIndicator status={step.status} size="sm" />
                  </div>
                  <div>
                    <h4 className="font-semibold text-neutral-200">{step.title}</h4>
                    <p className="text-[10px] text-neutral-500 mt-0.5">{step.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
        <Card className="p-4 space-y-3 h-fit">
          <h3 className="text-xs font-bold text-neutral-200">Dubai Freezone Parameters</h3>
          <div className="space-y-3 font-mono text-[10px] text-neutral-400">
            <div className="flex justify-between">
              <span>Corporate Tax:</span>
              <span className="text-neutral-200">0% under threshold</span>
            </div>
            <div className="flex justify-between">
              <span>Foreign Ownership:</span>
              <span className="text-emerald-400">100% allowed</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==========================================
// 6. FARM AGRI-TECH MONITOR VIEW
// ==========================================
export function FarmView() {
  const telemetry = [
    { label: "Soil Temperature", val: "28.5°C", status: "online" },
    { label: "Humidity", val: "68%", status: "online" },
    { label: "Soil moisture Index", val: "42%", status: "warning" },
    { label: "Valve Relay switch", val: "CLOSED", status: "disabled" }
  ];
  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6 text-xs text-left">
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Smart AgriTech Dashboard</h1>
          <p className="text-xs text-neutral-400 mt-1">IoT sensor telemetry monitoring camera feeds, soil metrics, and irrigation controls.</p>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            {telemetry.map((t, i) => (
              <Card key={i} className="p-4 flex justify-between items-center">
                <div>
                  <span className="text-neutral-500 text-[10px] uppercase font-mono">{t.label}</span>
                  <h3 className="text-base font-bold text-neutral-200 mt-1 font-mono">{t.val}</h3>
                </div>
                <StatusIndicator status={t.status} size="sm" />
              </Card>
            ))}
          </div>
          <Card className="aspect-video bg-neutral-900 border-white/5 rounded-xl flex items-center justify-center relative overflow-hidden">
            <div className="absolute inset-0 bg-neutral-950 flex flex-col p-4 justify-between">
              <div className="flex justify-between items-center text-[10px] font-mono text-neutral-400">
                <span>CCTV CAMERA FEED</span>
                <span className="flex items-center gap-1"><Droplet className="w-3.5 h-3.5 text-indigo-400" /> Sensor Active</span>
              </div>
              <div className="text-center text-neutral-600 font-mono font-bold">
                [LIVE HLS STREAM FEED MATRIX]
              </div>
              <div className="flex justify-between items-center text-[9px] text-neutral-500">
                <span>Location: Greenhouse A</span>
                <span>FPS: 24</span>
              </div>
            </div>
          </Card>
        </div>
        <Card className="p-4 space-y-4 h-fit">
          <h3 className="text-xs font-bold text-neutral-200">Irrigation Controls</h3>
          <p className="text-[10px] text-neutral-400 leading-relaxed">
            Irrigation is calibrated automatically depending on moisture telemetry. Toggling overrides will trigger local microcontrollers via FastAPI endpoints.
          </p>
          <Button variant="primary" className="w-full flex items-center justify-center gap-1.5 animate-pulse-slow">
            <Droplet className="w-4.5 h-4.5" />
            <span>Open irrigation valves</span>
          </Button>
        </Card>
      </div>
    </div>
  );
}
