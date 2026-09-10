"use client";

import type { CSSProperties, ReactNode } from "react";

import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AppSearchProvider } from "@/layouts/desktop/app-search";
import { Header } from "@/layouts/desktop/header";
import { Sidebar } from "@/layouts/desktop/sidebar";

type DesktopLayoutProps = {
  children: ReactNode;
};

export function DesktopLayout({ children }: DesktopLayoutProps) {
  return (
    <TooltipProvider>
      <AppSearchProvider>
        <SidebarProvider
          className="h-full min-h-0 min-w-0 flex-col overflow-hidden"
          style={{
            "--header-height": "4rem",
            "--content-aside-width": "22rem",
          } as CSSProperties}
        >
          <Header />
          <div className="flex min-h-0 min-w-0 flex-1 overflow-hidden pt-2 pr-2 pb-2">
            <Sidebar />
            <SidebarInset className="min-h-0 min-w-0 overflow-hidden md:peer-data-[variant=inset]:m-0 md:peer-data-[variant=inset]:peer-data-[state=collapsed]:ml-0">
              <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-x-hidden overflow-y-auto p-4 md:p-6 has-[[data-fill-viewport]]:overflow-hidden">
                {children}
              </div>
            </SidebarInset>
          </div>
        </SidebarProvider>
      </AppSearchProvider>
    </TooltipProvider>
  );
}
