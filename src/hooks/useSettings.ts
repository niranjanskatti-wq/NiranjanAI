import { useWorkspace } from "../context/WorkspaceContext";

export function useSettings() {
  const {
    apiKeys,
    setApiKeys,
    fastApiUrl,
    setFastApiUrl,
    theme,
    setTheme
  } = useWorkspace();

  return {
    apiKeys,
    setApiKeys,
    fastApiUrl,
    setFastApiUrl,
    theme,
    setTheme
  };
}
