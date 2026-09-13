"use client";

import { WorksDesktop } from "@/features/works/ui/desktop/works-desktop";
import { WorksMobile } from "@/features/works/ui/mobile/works-mobile";
import { useLockPortrait } from "@/hooks/use-lock-portrait";
import { useIsMobile } from "@/hooks/use-mobile";

export function WorksScreen() {
  useLockPortrait();
  const isMobile = useIsMobile();

  if (isMobile) {
    return <WorksMobile />;
  }

  return <WorksDesktop />;
}
