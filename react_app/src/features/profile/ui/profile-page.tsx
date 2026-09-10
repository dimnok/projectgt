"use client";

import { ProfileDesktop } from "@/features/profile/ui/desktop/profile-desktop";
import { ProfileMobile } from "@/features/profile/ui/mobile/profile-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function ProfilePage() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <ProfileMobile />;
  }

  return <ProfileDesktop />;
}
