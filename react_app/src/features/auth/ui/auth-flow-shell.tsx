import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

type AuthFlowShellProps = {
  children: ReactNode;
  className?: string;
};

/**
 * Общий контейнер экранов входа и онбординга: центрирует содержимое
 * и учитывает «безопасные» отступы телефона.
 */
export function AuthFlowShell({ children, className }: AuthFlowShellProps) {
  return (
    <div className="flex h-full min-h-0 flex-col overflow-y-auto">
      <div className="flex min-h-full w-full items-center justify-center px-6 py-8 pt-[max(1.5rem,env(safe-area-inset-top))] pb-[max(1.5rem,env(safe-area-inset-bottom))]">
        <div className={cn("w-full", className)}>{children}</div>
      </div>
    </div>
  );
}
