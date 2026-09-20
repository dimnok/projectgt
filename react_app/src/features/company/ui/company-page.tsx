"use client";

import { CompanyDesktop } from "@/features/company/ui/desktop/company-desktop";
import { CompanyMobile } from "@/features/company/ui/mobile/company-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function CompanyPage() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <CompanyMobile />;
  }

  return <CompanyDesktop />;
}
