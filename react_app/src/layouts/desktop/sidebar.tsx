"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { ChevronDownIcon, MoonIcon, SunIcon, ZapIcon } from "lucide-react";
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
import { MobileSidebarAccount } from "@/layouts/user-menu";
import { cn } from "@/lib/utils";

const comingSoonClass = "opacity-40";

const comingSoonMessage = "Этот раздел пока доступен только в приложении";

function notifyComingSoon() {
  toast.message(comingSoonMessage);
}

export function Sidebar() {
  const isMobile = useIsMobile();
  const { isMobile: isSidebarSheet } = useSidebar();
  const { can, isReady } = usePermissions();
  const viewportItems = filterNavigationForViewport(navigation, isMobile);
  const items = isReady
    ? filterNavigationByAccess(viewportItems, can)
    : viewportItems.filter((item) => !isNavGroup(item) && item.href === "/");

  return (
    <SidebarRoot variant="inset" collapsible="icon">
      <SidebarContent>
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
      <SidebarFooter>
        <ThemeToggle />
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
