"use client";

import { WorksDesktop } from "@/features/works/ui/desktop/works-desktop";
import { WorksMobile } from "@/features/works/ui/mobile/works-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function WorksScreen() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <WorksMobile />;
  }

  return <WorksDesktop />;
}
