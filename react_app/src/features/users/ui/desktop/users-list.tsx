"use client";

import { LinkIcon, ShieldIcon, UnlinkIcon } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { CompanyUser } from "@/features/users/types/user.types";
import { userDisplayName, userInitials } from "@/features/users/utils/user.utils";
import { formatPhone } from "@/lib/utils/phone";

type UsersListProps = {
  users: CompanyUser[];
  canLinkEmployee: boolean;
  canAssignRole: boolean;
  onAssign: (user: CompanyUser) => void;
  onAssignRole: (user: CompanyUser) => void;
};

function EmptyCell() {
  return <span className="text-muted-foreground">—</span>;
}

export function UsersList({
  users,
  canLinkEmployee,
  canAssignRole,
  onAssign,
  onAssignRole,
}: UsersListProps) {
  return (
    <Card size="sm" className="gap-0 overflow-hidden py-0 shadow-float">
      <Table>
        <TableCaption className="sr-only">Список пользователей</TableCaption>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Пользователь</TableHead>
            <TableHead>Роль</TableHead>
            <TableHead>Статус</TableHead>
            <TableHead>Карточка сотрудника</TableHead>
            <TableHead className="text-right">Действие</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {users.map((user) => {
            const name = userDisplayName(user);
            const phone = formatPhone(user.phone);

            return (
              <TableRow key={user.id}>
                <TableCell>
                  <div className="flex items-center gap-3">
                    <Avatar className="size-8">
                      {user.photoUrl ? (
                        <AvatarImage src={user.photoUrl} alt={name} />
                      ) : null}
                      <AvatarFallback>{userInitials(user)}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <p className="truncate font-medium">{name}</p>
                      <p className="truncate text-xs text-muted-foreground">
                        {phone || user.email || "Контакт не указан"}
                      </p>
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant={user.isOwner ? "secondary" : "outline"}>
                    {user.roleName}
                  </Badge>
                </TableCell>
                <TableCell>
                  {user.isActive ? (
                    <Badge variant="outline" className="text-emerald-600">
                      Активен
                    </Badge>
                  ) : (
                    <Badge variant="secondary">Неактивен</Badge>
                  )}
                </TableCell>
                <TableCell>
                  {user.linkedEmployee ? (
                    <div className="min-w-0">
                      <p className="truncate font-medium">
                        {user.linkedEmployee.fullName}
                      </p>
                      <p className="truncate text-xs text-muted-foreground">
                        {user.linkedEmployee.position || "Должность не указана"}
                      </p>
                    </div>
                  ) : (
                    <EmptyCell />
                  )}
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end gap-1.5">
                    {canAssignRole ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="gap-1.5"
                        onClick={() => onAssignRole(user)}
                      >
                        <ShieldIcon />
                        Роль
                      </Button>
                    ) : null}
                    {canLinkEmployee ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="gap-1.5"
                        onClick={() => onAssign(user)}
                      >
                        {user.employeeId ? (
                          <UnlinkIcon />
                        ) : (
                          <LinkIcon />
                        )}
                        {user.employeeId ? "Сменить" : "Привязать"}
                      </Button>
                    ) : null}
                  </div>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </Card>
  );
}
