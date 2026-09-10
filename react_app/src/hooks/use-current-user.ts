"use client";

import { useAuth } from "@/hooks/use-auth";
import { formatPhone } from "@/lib/utils/phone";
import type { CurrentUser } from "@/types/user.types";

/**
 * Returns the signed-in user, or `null` when there is no session.
 */
export function useCurrentUser(): CurrentUser | null {
  const { session } = useAuth();
  if (!session?.user) {
    return null;
  }

  return {
    id: session.user.id,
    displayName: formatPhone(session.user.phone) || "Пользователь",
  };
}
