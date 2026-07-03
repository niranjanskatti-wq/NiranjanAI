import { useWorkspace } from "../context/WorkspaceContext";

export function useTasks() {
  const { tasks, isExecuting, runPrompt } = useWorkspace();

  const getTaskById = (id: string) => {
    return tasks.find((t) => t.id === id);
  };

  const getRunningTasksCount = () => {
    return tasks.filter((t) => t.status === "running").length;
  };

  return {
    tasks,
    isExecuting,
    runPrompt,
    getTaskById,
    getRunningTasksCount
  };
}
