"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState } from "react";
import {
  ChevronDownIcon,
  CircleHelpIcon,
  MoonIcon,
  SunIcon,
  XIcon,
  ZapIcon,
} from "lucide-react";
import { useTheme } from "next-themes";
import { toast } from "sonner";

import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { Separator } from "@/components/ui/separator";
import {
  Sidebar as SidebarRoot,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarMenuSub,
  SidebarMenuSubButton,
  SidebarMenuSubItem,
  useSidebar,
} from "@/components/ui/sidebar";
import {
  filterNavigationByAccess,
  filterNavigationForViewport,
  isActivePath,
  isNavGroup,
  navigation,
  type AppNavGroup,
  type AppNavLink,
} from "@/config/navigation";
import { useHasMounted } from "@/hooks/use-has-mounted";
import { useIsMobile } from "@/hooks/use-mobile";
import { usePermissions } from "@/hooks/use-permissions";
import { launchWorksHelpTour } from "@/features/works/tour/launch-works-help-tour";
import { MobileSidebarAccount } from "@/layouts/user-menu";
import { cn } from "@/lib/utils";

const comingSoonClass = "opacity-40";

const comingSoonMessage = "Этот раздел пока доступен только в приложении";

function notifyComingSoon() {
  toast.message(comingSoonMessage);
}

export function Sidebar() {
  const isMobile = useIsMobile();
  const { isMobile: isSidebarSheet, setOpenMobile } = useSidebar();
  const { can, isReady } = usePermissions();
  const viewportItems = filterNavigationForViewport(navigation, isMobile);
  const items = isReady
    ? filterNavigationByAccess(viewportItems, can)
    : viewportItems.filter((item) => !isNavGroup(item) && item.href === "/");

  return (
    <SidebarRoot variant="inset" collapsible="icon">
      {isSidebarSheet ? (
        <div className="flex h-16 shrink-0 items-center justify-between border-b border-sidebar-border/60 px-4 pt-[max(0.75rem,env(safe-area-inset-top))] pl-6">
          <div className="flex items-center gap-2.5">
            <div className="flex size-8 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground font-bold text-xs shadow-sm">
              GT
            </div>
            <div className="flex flex-col">
              <span className="font-heading text-sm font-semibold tracking-tight text-sidebar-foreground">
                Стройка PRO
              </span>
              <span className="text-[10px] uppercase tracking-wider text-sidebar-foreground/50 font-medium">
                Меню
              </span>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setOpenMobile(false)}
            aria-label="Закрыть меню"
            className="flex size-8 items-center justify-center rounded-full text-sidebar-foreground/70 transition-colors hover:bg-sidebar-accent hover:text-sidebar-foreground active:scale-90"
          >
            <XIcon className="size-4" />
          </button>
        </div>
      ) : null}
      <SidebarContent className={isSidebarSheet ? "pl-2" : undefined}>
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu>
              {items.map((item) =>
                isNavGroup(item) ? (
                  <NavGroupItem key={item.label} item={item} />
                ) : (
                  <NavLinkItem key={item.href} item={item} />
                )
              )}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className={isSidebarSheet ? "pb-[max(1rem,env(safe-area-inset-bottom))] pl-2" : undefined}>
        <ThemeToggle />
        <WorksHelpItem />
        {isSidebarSheet ? (
          <>
            <Separator className="mx-0 bg-sidebar-border" />
            <MobileSidebarAccount />
          </>
        ) : null}
      </SidebarFooter>
    </SidebarRoot>
  );
}

function NavLinkItem({ item }: { item: AppNavLink }) {
  const pathname = usePathname();
  const { isMobile, setOpenMobile } = useSidebar();
  const Icon = item.icon;
  const isActive = isActivePath(pathname, item.href);

  if (!item.migrated) {
    return (
      <SidebarMenuItem>
        <SidebarMenuButton
          className={comingSoonClass}
          tooltip={item.label}
          onClick={notifyComingSoon}
        >
          <Icon />
          <span>{item.label}</span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    );
  }

  return (
    <SidebarMenuItem>
      <SidebarMenuButton
        render={<Link href={item.href} />}
        isActive={isActive}
        tooltip={item.label}
        onClick={() => {
          if (isMobile) {
            setOpenMobile(false);
          }
        }}
      >
        <Icon />
        <span>{item.label}</span>
      </SidebarMenuButton>
    </SidebarMenuItem>
  );
}

function NavGroupItem({ item }: { item: AppNavGroup }) {
  const pathname = usePathname();
  const childActive = item.children.some((child) =>
    isActivePath(pathname, child.href)
  );
  const [open, setOpen] = useState(childActive);
  const Icon = item.icon;

  return (
    <SidebarMenuItem>
      <Collapsible
        open={open || childActive}
        onOpenChange={setOpen}
        className="group/collapsible"
      >
        <CollapsibleTrigger
          render={<SidebarMenuButton tooltip={item.label} />}
        >
          <Icon />
          <span>{item.label}</span>
          <ChevronDownIcon className="ml-auto transition-transform group-data-open/collapsible:rotate-180" />
        </CollapsibleTrigger>
        <CollapsibleContent>
          <SidebarMenuSub className="mx-3.5 border-l-0 px-0">
            {item.children.map((child, index) => (
              <NavSubItem
                key={child.href}
                item={child}
                isLast={index === item.children.length - 1}
              />
            ))}
          </SidebarMenuSub>
        </CollapsibleContent>
      </Collapsible>
    </SidebarMenuItem>
  );
}

function NavSubItem({
  item,
  isLast,
}: {
  item: AppNavLink;
  isLast: boolean;
}) {
  const pathname = usePathname();
  const { isMobile, setOpenMobile } = useSidebar();
  const isActive = isActivePath(pathname, item.href);

  return (
    <SidebarMenuSubItem className="relative">
      <span
        className={cn(
          "pointer-events-none absolute top-0 left-0 w-px bg-sidebar-border",
          isLast ? "h-1/2" : "h-full"
        )}
      />
      <span className="pointer-events-none absolute top-1/2 left-0 h-px w-3 bg-sidebar-border" />
      {item.migrated ? (
        <SidebarMenuSubButton
          render={<Link href={item.href} />}
          isActive={isActive}
          className="ml-3"
          onClick={() => {
            if (isMobile) {
              setOpenMobile(false);
            }
          }}
        >
          <span>{item.label}</span>
        </SidebarMenuSubButton>
      ) : (
        <SidebarMenuSubButton
          href="#coming-soon"
          className={cn("ml-3", comingSoonClass)}
          onClick={(event) => {
            event.preventDefault();
            notifyComingSoon();
          }}
        >
          <span>{item.label}</span>
        </SidebarMenuSubButton>
      )}
    </SidebarMenuSubItem>
  );
}

function WorksHelpItem() {
  const pathname = usePathname();
  const router = useRouter();
  const isMobile = useIsMobile();
  const { isMobile: isSidebarSheet, setOpenMobile } = useSidebar();
  const { can, isReady } = usePermissions();

  function runHelp() {
    const result = launchWorksHelpTour({
      isMobile,
      pathname,
      canOpenWorks: isReady && can("works", "read"),
      goToWorks: () => router.push("/works"),
    });
    if (result === "denied") {
      toast.message("Подсказки доступны в разделе «Смены»");
    }
  }

  function handleHelp() {
    if (isSidebarSheet) {
      setOpenMobile(false);
      window.setTimeout(runHelp, 320);
      return;
    }
    runHelp();
  }

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <SidebarMenuButton
          type="button"
          tooltip="Помощь"
          onClick={handleHelp}
        >
          <CircleHelpIcon />
          <span>Помощь</span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    </SidebarMenu>
  );
}

function themeToggleButtonClass(isActive: boolean) {
  return cn(
    "flex size-7 items-center justify-center rounded-full [&_svg]:size-4",
    isActive
      ? "bg-background text-foreground shadow-sm"
      : "text-sidebar-foreground/70"
  );
}

function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const mounted = useHasMounted();

  if (!mounted) {
    return <div className="h-8" />;
  }

  return (
    <div className="flex items-center justify-center gap-1 rounded-full bg-sidebar-accent p-1 group-data-[collapsible=icon]:hidden">
      <button
        type="button"
        aria-label="Светлая тема"
        className={themeToggleButtonClass(resolvedTheme === "light")}
        onClick={() => setTheme("light")}
      >
        <SunIcon />
      </button>
      <button
        type="button"
        aria-label="Тёмная тема"
        className={themeToggleButtonClass(resolvedTheme === "dark")}
        onClick={() => setTheme("dark")}
      >
        <MoonIcon />
      </button>
      <button
        type="button"
        aria-label="Фирменная тема"
        className={themeToggleButtonClass(resolvedTheme === "brand")}
        onClick={() => setTheme("brand")}
      >
        <ZapIcon />
      </button>
    </div>
  );
}
