import { useWorkspace } from "../context/WorkspaceContext";

export function usePlugins() {
  const { plugins, togglePlugin } = useWorkspace();

  const getEnabledPlugins = () => {
    return plugins.filter((p) => p.enabled);
  };

  const getHealthyPlugins = () => {
    return plugins.filter((p) => p.health === "healthy");
  };

  return {
    plugins,
    togglePlugin,
    getEnabledPlugins,
    getHealthyPlugins
  };
}
