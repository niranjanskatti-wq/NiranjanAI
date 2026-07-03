import { useWorkspace } from "../context/WorkspaceContext";

export function useModels() {
  const { models, activeModel, setActiveModel } = useWorkspace();

  const getActiveModelDetails = () => {
    return models.find((m) => m.id === activeModel);
  };

  const getOnlineModels = () => {
    return models.filter((m) => m.status === "online");
  };

  return {
    models,
    activeModel,
    setActiveModel,
    getActiveModelDetails,
    getOnlineModels
  };
}
