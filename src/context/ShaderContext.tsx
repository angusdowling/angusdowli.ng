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
// How much of the previous transition momentum to carry forward (0-1)
const MOMENTUM_CARRY = 0.4;

const ShaderContext = createContext<ShaderContextType | null>(null);

export function ShaderProvider({ children }: { children: ReactNode }) {
  // Use refs for all state to avoid re-render issues in animation loop
  const projectIndex = useRef(0);
  const previousProject = useRef(0);
  const transitionStartTime = useRef<number | null>(null);
  const projectStartTime = useRef<number | null>(null);
  // Track the last computed progress to carry momentum on rapid switches
  const lastProgress = useRef(1);
  const lastTime = useRef(0);

  const selectProject = useCallback((index: number) => {
    // Calculate how much momentum to carry forward from current transition
    let timeOffset = 0;

    if (lastProgress.current < 1 && lastProgress.current > 0) {
      // We're mid-transition - carry forward some momentum
      // This prevents the jarring snap when quickly hovering through items
      const carriedProgress = lastProgress.current * MOMENTUM_CARRY;
      timeOffset = carriedProgress * TRANSITION_DURATION;

      // If we were more than halfway through, use the target as the new previous
      // This makes the visual transition smoother
      if (lastProgress.current > 0.5) {
        previousProject.current = projectIndex.current;
      }
      // Otherwise keep the existing previousProject for continuity
    } else {
      previousProject.current = projectIndex.current;
    }

    projectIndex.current = index;
    // Set start time with offset to account for carried momentum
    // Will be adjusted on first getShaderState call
    transitionStartTime.current =
      timeOffset > 0 ? lastTime.current - timeOffset : null;
    projectStartTime.current = null;
  }, []);

  const clearProject = useCallback(() => {
    // Calculate how much momentum to carry forward
    let timeOffset = 0;

    if (lastProgress.current < 1 && lastProgress.current > 0) {
      const carriedProgress = lastProgress.current * MOMENTUM_CARRY;
      timeOffset = carriedProgress * TRANSITION_DURATION;

      if (lastProgress.current > 0.5) {
        previousProject.current = projectIndex.current;
      }
    } else {
      previousProject.current = projectIndex.current;
    }

    projectIndex.current = 0;
    transitionStartTime.current =
      timeOffset > 0 ? lastTime.current - timeOffset : null;
    projectStartTime.current = null;
  }, []);

  // Called every frame from the animation loop
  const getShaderState = useCallback((currentTime: number): ShaderState => {
    lastTime.current = currentTime;

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

    // Store for momentum calculation on next switch
    lastProgress.current = transitionProgress;

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
