"use client";

import React, { useState } from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import {
  Search,
  Clock,
  Terminal,
  Cpu
} from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { Modal } from "@/components/ui/Modal";
import { Task } from "@/types/task";

export function TasksView() {
  const { tasks } = useWorkspace();
  const [search, setSearch] = useState("");
  const [priorityFilter, setPriorityFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);

  const filteredTasks = tasks.filter((t) => {
    const matchesSearch = t.title.toLowerCase().includes(search.toLowerCase()) || 
                          t.agentUsed.toLowerCase().includes(search.toLowerCase());
    const matchesPriority = priorityFilter === "all" || t.priority === priorityFilter;
    const matchesStatus = statusFilter === "all" || t.status === statusFilter;
    return matchesSearch && matchesPriority && matchesStatus;
  });

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center border-b border-white/5 pb-4">
        <div>
          <h1 className="text-xl font-bold text-white">Agent Execution Logs</h1>
          <p className="text-xs text-neutral-400 mt-1">Audit background automation routines and task execution metrics.</p>
        </div>
      </div>

      {/* Filters toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 items-center justify-between bg-white/5 border border-white/5 rounded-xl p-3">
        <div className="relative w-full sm:max-w-xs group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-500 group-focus-within:text-indigo-400" />
          <input
            type="text"
            placeholder="Filter tasks..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-white/5 border border-white/10 rounded-lg pl-9 pr-4 py-1.5 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/50"
          />
        </div>

        <div className="flex gap-3 w-full sm:w-auto">
          {/* Priority filter */}
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="bg-white/5 border border-white/10 text-neutral-300 text-xs rounded-lg p-2 focus:outline-none focus:border-indigo-500/50 cursor-pointer"
          >
            <option value="all">All Priorities</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>

          {/* Status filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-white/5 border border-white/10 text-neutral-300 text-xs rounded-lg p-2 focus:outline-none focus:border-indigo-500/50 cursor-pointer"
          >
            <option value="all">All Statuses</option>
            <option value="running">Running</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
            <option value="queued">Queued</option>
          </select>
        </div>
      </div>

      {/* Task table grid */}
      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-neutral-900 border-b border-white/5 text-neutral-400 font-semibold uppercase tracking-wider">
                <th className="p-4">Task Details</th>
                <th className="p-4">Agent Used</th>
                <th className="p-4">Priority</th>
                <th className="p-4">Status</th>
                <th className="p-4">Runtime</th>
                <th className="p-4">Timeline</th>
                <th className="p-4 text-center">Logs</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-neutral-300">
              {filteredTasks.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-neutral-500 font-mono">
                    No active tasks found in database matching criteria.
                  </td>
                </tr>
              ) : (
                filteredTasks.map((task) => {
                  let priorityColor = "bg-neutral-500/10 text-neutral-400 border border-neutral-500/20";
                  if (task.priority === "critical") {
                    priorityColor = "bg-rose-500/10 text-rose-400 border border-rose-500/20";
                  } else if (task.priority === "high") {
                    priorityColor = "bg-amber-500/10 text-amber-400 border border-amber-500/20";
                  } else if (task.priority === "medium") {
                    priorityColor = "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20";
                  }

                  return (
                    <tr key={task.id} className="hover:bg-white/5 transition-colors">
                      <td className="p-4 font-semibold text-neutral-200">
                        <div>
                          <p>{task.title}</p>
                          <span className="text-[9px] font-mono text-neutral-500">ID: {task.id}</span>
                        </div>
                      </td>
                      <td className="p-4 font-mono text-neutral-400">
                        <div className="flex items-center gap-1.5">
                          <Cpu className="w-3.5 h-3.5 text-neutral-500" />
                          <span>{task.agentUsed}</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold tracking-wide ${priorityColor}`}>
                          {task.priority}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-1.5">
                          <StatusIndicator status={task.status} size="sm" />
                          <span className="text-[11px] capitalize">{task.status}</span>
                        </div>
                      </td>
                      <td className="p-4 font-mono text-neutral-400">
                        <div className="flex items-center gap-1">
                          <Clock className="w-3 h-3 text-neutral-600" />
                          {task.executionTime}
                        </div>
                      </td>
                      <td className="p-4 text-neutral-500 font-mono">{task.timestamp}</td>
                      <td className="p-4 text-center">
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => setSelectedTask(task)}
                          className="px-2.5 py-1 text-[10px] min-w-0"
                        >
                          <Terminal className="w-3.5 h-3.5 mr-1" />
                          Inspect
                        </Button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Logs Inspection Modal */}
      <Modal
        isOpen={selectedTask !== null}
        onClose={() => setSelectedTask(null)}
        title={selectedTask ? `Console Log Inspection: ${selectedTask.title}` : ""}
      >
        {selectedTask && (
          <div className="space-y-4">
            <div className="flex justify-between items-center bg-white/5 border border-white/5 rounded-lg p-3 text-xs">
              <div>
                <span className="text-neutral-500">Agent:</span>{" "}
                <span className="font-semibold text-neutral-200">{selectedTask.agentUsed}</span>
              </div>
              <div>
                <span className="text-neutral-500">Duration:</span>{" "}
                <span className="font-semibold text-neutral-200 font-mono">{selectedTask.executionTime}</span>
              </div>
              <div className="flex items-center gap-1">
                <StatusIndicator status={selectedTask.status} size="sm" />
                <span className="capitalize text-neutral-300 font-semibold">{selectedTask.status}</span>
              </div>
            </div>

            <div className="bg-black/95 rounded-lg border border-white/10 p-4 font-mono text-[10px] text-green-400 overflow-x-auto h-64 shadow-inner space-y-1.5 animate-pulse-slow">
              {selectedTask.logs && selectedTask.logs.length > 0 ? (
                selectedTask.logs.map((log, index) => {
                  const isErr = log.includes("[ERROR]");
                  return (
                    <div key={index} className={isErr ? "text-rose-400" : ""}>
                      {log}
                    </div>
                  );
                })
              ) : (
                <div className="text-neutral-500 italic">No historical logs available for this task.</div>
              )}
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedTask(null)}>
                Close
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
