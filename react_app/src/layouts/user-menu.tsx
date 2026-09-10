"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { LogOutIcon, UserRoundIcon } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import {
  profileDisplayName,
  profileInitials,
} from "@/features/profile/utils/profile.utils";
import { useCurrentUser } from "@/hooks/use-current-user";
import { signOut } from "@/lib/supabase/auth";

function useAccountLabel() {
  const sessionUser = useCurrentUser();
  const { data: profile } = useCurrentProfile();
  const name = profile
    ? profileDisplayName(profile)
    : (sessionUser?.displayName ?? "Пользователь");
  const photoUrl = profile?.photoUrl ?? undefined;

  return { name, photoUrl };
}

export function UserMenu() {
  const { name, photoUrl } = useAccountLabel();
  const router = useRouter();

  async function handleSignOut() {
    await signOut();
    router.replace("/login");
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            variant="ghost"
            size="icon"
            className="rounded-full"
            aria-label="Меню пользователя"
          />
        }
      >
        <Avatar>
          {photoUrl ? <AvatarImage src={photoUrl} alt={name} /> : null}
          <AvatarFallback>{profileInitials(name)}</AvatarFallback>
        </Avatar>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuGroup>
          <DropdownMenuLabel className="truncate">{name}</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => router.push("/profile")}>
            <UserRoundIcon />
            Профиль
          </DropdownMenuItem>
          <DropdownMenuItem variant="destructive" onClick={handleSignOut}>
            <LogOutIcon />
            Выйти
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export function MobileSidebarAccount() {
  const { name, photoUrl } = useAccountLabel();
  const { setOpenMobile } = useSidebar();

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <SidebarMenuButton
          size="lg"
          render={<Link href="/profile" />}
          onClick={() => setOpenMobile(false)}
        >
          <Avatar size="sm">
            {photoUrl ? <AvatarImage src={photoUrl} alt={name} /> : null}
            <AvatarFallback>{profileInitials(name)}</AvatarFallback>
          </Avatar>
          <span className="truncate">{name}</span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    </SidebarMenu>
  );
}
