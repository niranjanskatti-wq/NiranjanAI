import { useWorkspace } from "../context/WorkspaceContext";

export function useHermes() {
  const { agents, terminalLogs, activeModel, runPrompt } = useWorkspace();

  const getAgentById = (id: string) => {
    return agents.find((a) => a.id === id);
  };

  const getActiveAgentCount = () => {
    return agents.filter((a) => a.status === "online").length;
  };

  const getSystemDiagnostics = () => {
    const totalHealth = agents.reduce((acc, a) => acc + a.health, 0);
    const avgHealth = agents.length > 0 ? Math.round(totalHealth / agents.length) : 100;
    return {
      averageAgentHealth: avgHealth,
      agentCount: agents.length,
      gatewayState: "online" as const
    };
  };

  return {
    agents,
    terminalLogs,
    activeModel,
    runPrompt,
    getAgentById,
    getActiveAgentCount,
    getSystemDiagnostics
  };
}
