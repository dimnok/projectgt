"use client";

import { GtDiskDesktop } from "@/features/gt-disk/ui/desktop/gt-disk-desktop";
import { GtDiskMobile } from "@/features/gt-disk/ui/mobile/gt-disk-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function GtDiskPage() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <GtDiskMobile />;
  }

  return <GtDiskDesktop />;
}
