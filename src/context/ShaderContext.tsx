import {
  createContext,
  useContext,
  useCallback,
  useRef,
  ReactNode,
} from "react";

export interface ShaderState {
  projectIndex: number; // 0 = none, 1-6 = projects
  transitionProgress: number; // 0-1, animated
  projectTime: number; // Time since project selected
  previousProject: number; // For blending during transitions
}

interface ShaderContextType {
  selectProject: (index: number) => void;
  clearProject: () => void;
  getShaderState: (currentTime: number) => ShaderState;
}

const TRANSITION_DURATION = 0.8; // seconds

const ShaderContext = createContext<ShaderContextType | null>(null);

export function ShaderProvider({ children }: { children: ReactNode }) {
  // Use refs for all state to avoid re-render issues in animation loop
  const projectIndex = useRef(0);
  const previousProject = useRef(0);
  const transitionStartTime = useRef<number | null>(null);
  const projectStartTime = useRef<number | null>(null);

  const selectProject = useCallback((index: number) => {
    previousProject.current = projectIndex.current;
    projectIndex.current = index;
    transitionStartTime.current = null; // Will be set on first getShaderState call
    projectStartTime.current = null; // Will be set on first getShaderState call
  }, []);

  const clearProject = useCallback(() => {
    previousProject.current = projectIndex.current;
    projectIndex.current = 0;
    transitionStartTime.current = null;
    projectStartTime.current = null;
  }, []);

  // Called every frame from the animation loop
  const getShaderState = useCallback((currentTime: number): ShaderState => {
    // Initialize timestamps on first call after state change
    if (transitionStartTime.current === null) {
      transitionStartTime.current = currentTime;
    }
    if (projectStartTime.current === null && projectIndex.current > 0) {
      projectStartTime.current = currentTime;
    }

    // Calculate transition progress
    let transitionProgress = 1;
    const elapsed = currentTime - transitionStartTime.current;
    if (elapsed < TRANSITION_DURATION) {
      const progress = elapsed / TRANSITION_DURATION;
      // Smooth easing
      transitionProgress = progress * progress * (3 - 2 * progress);
    } else {
      // Transition complete - sync previousProject to avoid unnecessary blending
      previousProject.current = projectIndex.current;
    }

    // Calculate project time (time since project was selected)
    let projectTime = 0;
    if (projectIndex.current > 0 && projectStartTime.current !== null) {
      projectTime = currentTime - projectStartTime.current;
    }

    return {
      projectIndex: projectIndex.current,
      previousProject: previousProject.current,
      transitionProgress,
      projectTime,
    };
  }, []);

  return (
    <ShaderContext.Provider
      value={{ selectProject, clearProject, getShaderState }}
    >
      {children}
    </ShaderContext.Provider>
  );
}

export function useShader() {
  const context = useContext(ShaderContext);
  if (!context) {
    throw new Error("useShader must be used within a ShaderProvider");
  }
  return context;
}
