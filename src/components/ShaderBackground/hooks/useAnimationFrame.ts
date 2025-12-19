import { useEffect, useRef } from "react";

interface FrameData {
  time: number;
  deltaTime: number;
}

type FrameCallback = (frame: FrameData) => void;

export function useAnimationFrame(callback: FrameCallback) {
  const frameRef = useRef<number>(0);
  const startTimeRef = useRef(Date.now());
  const lastFrameRef = useRef(Date.now());
  const callbackRef = useRef(callback);

  callbackRef.current = callback;

  useEffect(() => {
    const animate = () => {
      const now = Date.now();
      const deltaTime = (now - lastFrameRef.current) / 1000;
      const time = (now - startTimeRef.current) / 1000;
      lastFrameRef.current = now;

      callbackRef.current({ time, deltaTime });
      frameRef.current = requestAnimationFrame(animate);
    };

    frameRef.current = requestAnimationFrame(animate);

    return () => cancelAnimationFrame(frameRef.current);
  }, []);
}
