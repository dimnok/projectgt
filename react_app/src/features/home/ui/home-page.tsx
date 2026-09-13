"use client";

import { HomeDesktop } from "@/features/home/ui/desktop/home-desktop";
import { HomeMobile } from "@/features/home/ui/mobile/home-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function HomePage() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <HomeMobile />;
  }

  return <HomeDesktop />;
}
