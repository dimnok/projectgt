"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import type { CompanyUser } from "@/features/users/types/user.types";
import { countCompanyUsers } from "@/features/users/utils/user.utils";

type UsersSummaryProps = {
  users: CompanyUser[];
};

export function UsersSummary({ users }: UsersSummaryProps) {
  const counts = countCompanyUsers(users);

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Сводка</CardTitle>
        <CardDescription>Пользователи активной компании</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-4 max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:justify-between max-lg:gap-x-4 max-lg:gap-y-2">
        <div className="flex flex-col gap-1 max-lg:flex-row max-lg:items-baseline max-lg:gap-2">
          <p className="text-sm text-muted-foreground">Всего</p>
          <p className="font-heading text-2xl font-medium tabular-nums max-lg:text-base">
            {counts.total}
          </p>
        </div>
        <ul className="flex flex-col gap-2 text-sm max-lg:flex-row max-lg:flex-wrap max-lg:gap-x-4">
          <li className="flex items-center justify-between gap-3">
            <span className="text-muted-foreground">С карточкой</span>
            <span className="tabular-nums font-medium">{counts.linked}</span>
          </li>
          <li className="flex items-center justify-between gap-3">
            <span className="text-muted-foreground">Без карточки</span>
            <span className="tabular-nums font-medium">{counts.unlinked}</span>
          </li>
          <li className="flex items-center justify-between gap-3">
            <span className="text-muted-foreground">Неактивны</span>
            <span className="tabular-nums font-medium">{counts.inactive}</span>
          </li>
          <li className="flex items-center justify-between gap-3">
            <span className="text-muted-foreground">Без объектов</span>
            <span className="tabular-nums font-medium">{counts.withoutObjects}</span>
          </li>
          <li className="flex items-center justify-between gap-3">
            <span className="text-muted-foreground">На сайте</span>
            <span className="tabular-nums font-medium">{counts.onWeb}</span>
          </li>
        </ul>
      </CardContent>
    </Card>
  );
}
