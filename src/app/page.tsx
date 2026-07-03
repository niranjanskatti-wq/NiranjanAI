"use client";

import React from "react";
import { useWorkspace } from "@/context/WorkspaceContext";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import { ActivitySidebar } from "@/components/layout/ActivitySidebar";
import { Footer } from "@/components/layout/Footer";

// View components from Feature Folders
import { DashboardView } from "@/features/dashboard/components/DashboardView";
import { AIChatView } from "@/features/chat/components/AIChatView";
import { TasksView } from "@/features/tasks/components/TasksView";
import { DocumentsView } from "@/features/documents/components/DocumentsView";
import { PluginsView } from "@/features/plugins/components/PluginsView";
import { ModelsView } from "@/features/models/components/ModelsView";
import { SettingsView } from "@/features/settings/components/SettingsView";

// Specialized views from Feature Folders
import {
  ResearchView,
  BrowserView,
  AutomationView,
  FlightsView,
  IFZAView,
  FarmView
} from "@/features/specialized/components/SpecializedAgentsView";

export default function Home() {
  const { activeView } = useWorkspace();

  const renderActiveView = () => {
    switch (activeView) {
      case "dashboard":
        return <DashboardView />;
      case "chat":
        return <AIChatView />;
      case "tasks":
        return <TasksView />;
      case "documents":
        return <DocumentsView />;
      case "plugins":
        return <PluginsView />;
      case "models":
        return <ModelsView />;
      case "settings":
        return <SettingsView />;
      case "research":
        return <ResearchView />;
      case "browser":
        return <BrowserView />;
      case "automation":
        return <AutomationView />;
      case "flights":
        return <FlightsView />;
      case "ifza":
        return <IFZAView />;
      case "farm":
        return <FarmView />;
      default:
        return <DashboardView />;
    }
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-bg-obsidian text-foreground font-sans">
      {/* 1. Left Sidebar Navigation */}
      <Sidebar />

      {/* 2. Main content container */}
      <div className="flex-1 flex flex-col h-full min-w-0 overflow-hidden bg-neutral-900/10">
        {/* Top Control Header */}
        <Header />

        {/* View Workspace Content Panel */}
        <main className="flex-1 flex flex-col min-h-0 overflow-hidden relative">
          {renderActiveView()}
        </main>

        {/* Bottom Status bar */}
        <Footer />
      </div>

      {/* 3. Right Activity logs Feed */}
      <ActivitySidebar />
    </div>
  );
}
