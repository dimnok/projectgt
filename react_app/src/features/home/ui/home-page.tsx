"use client";

import Link from "next/link";

import { Button } from "@/components/ui/button";
import { usePermissions } from "@/hooks/use-permissions";

const LINKS: { href: string; label: string; module: string | null; variant?: "outline" }[] = [
  { href: "/objects", label: "Объекты", module: "objects" },
  { href: "/contractors", label: "Контрагенты", module: "contractors", variant: "outline" },
  { href: "/contracts", label: "Договоры", module: "contracts", variant: "outline" },
  { href: "/estimates", label: "Сметы", module: "estimates", variant: "outline" },
  { href: "/employees", label: "Сотрудники", module: "employees", variant: "outline" },
  { href: "/works", label: "Работы", module: "works", variant: "outline" },
  { href: "/work-journal", label: "Журнал работ", module: "export", variant: "outline" },
  { href: "/timesheet", label: "Табель", module: "timesheet", variant: "outline" },
  { href: "/users", label: "Пользователи", module: "users", variant: "outline" },
  { href: "/roles", label: "Роли", module: "roles", variant: "outline" },
  { href: "/profile", label: "Профиль", module: null, variant: "outline" },
];

export function HomePage() {
  const { can } = usePermissions();
  const links = LINKS.filter((link) => !link.module || can(link.module, "read"));

  return (
    <div className="mx-auto flex min-h-0 w-full max-w-xl flex-1 flex-col gap-4 overflow-y-auto">
      <p className="text-muted-foreground">
        Веб-версия. Разделы в меню зависят от вашей роли.
      </p>
      <div className="flex flex-wrap gap-2">
        {links.map((link) => (
          <Button
            key={link.href}
            variant={link.variant}
            render={<Link href={link.href} />}
            nativeButton={false}
          >
            {link.label}
          </Button>
        ))}
      </div>
    </div>
  );
}
