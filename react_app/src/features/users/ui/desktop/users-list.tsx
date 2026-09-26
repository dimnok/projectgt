"use client";

import {
  ArrowDownIcon,
  ArrowUpDownIcon,
  ArrowUpIcon,
  BanIcon,
  CircleCheckIcon,
  EllipsisIcon,
  FolderKanbanIcon,
  ShieldIcon,
  UnlinkIcon,
  UserCheckIcon,
} from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type {
  CompanyUser,
  CompanyUserSort,
  CompanyUserSortKey,
} from "@/features/users/types/user.types";
import { UserPreferWebSwitch } from "@/features/users/ui/shared/user-prefer-web-switch";
import {
  userDisplayName,
  userInitials,
  userObjectNames,
} from "@/features/users/utils/user.utils";
import {
  nextTableSort,
  tableSortAriaSort,
  tableSortTitle,
  type SortDirection,
} from "@/lib/table-sort";
import { cn } from "@/lib/utils";
import { formatPhone } from "@/lib/utils/phone";

type UsersListProps = {
  users: CompanyUser[];
  objects: { id: string; name: string }[];
  canLinkEmployee: boolean;
  canAssignObjects: boolean;
  canAssignRole: boolean;
  canChangeStatus: boolean;
  canPreferWebApp: boolean;
  sort: CompanyUserSort;
  onSortChange: (next: CompanyUserSort) => void;
  onAssign: (user: CompanyUser) => void;
  onAssignRole: (user: CompanyUser) => void;
  onAssignObjects: (user: CompanyUser) => void;
  onChangeStatus: (user: CompanyUser) => void;
};

/** Однотонная подложка шапки: в тёмных темах «muted» совпадает с карточкой. */
const HEAD_BG = "bg-[color-mix(in_oklch,var(--card),var(--foreground)_4%)]";
const HEAD_CELL = `sticky top-0 z-10 border-b border-border/80 ${HEAD_BG} text-xs font-semibold whitespace-nowrap text-foreground/75 select-none align-middle`;

function EmptyCell() {
  return <span className="text-muted-foreground">—</span>;
}

/** Заголовок с сортировкой: клик — прямо, ещё раз — обратно, третий — сброс. */
function SortableHead({
  columnKey,
  label,
  sort,
  onSortChange,
  sortFirst = "asc",
  hint,
  className,
}: {
  columnKey: CompanyUserSortKey;
  label: string;
  sort: CompanyUserSort;
  onSortChange: (next: CompanyUserSort) => void;
  sortFirst?: SortDirection;
  hint?: string;
  className?: string;
}) {
  const isSorted = sort?.key === columnKey;
  const nextSort = nextTableSort(columnKey, sort, sortFirst);
  const sortTitle = tableSortTitle(columnKey, sort, sortFirst);

  return (
    <TableHead
      aria-sort={tableSortAriaSort(columnKey, sort)}
      title={hint ? `${hint}. ${sortTitle}` : sortTitle}
      className={cn(HEAD_CELL, className)}
    >
      <button
        type="button"
        onClick={() => onSortChange(nextSort)}
        title={sortTitle}
        className={cn(
          "inline-flex cursor-pointer items-center gap-1 rounded-sm transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
          isSorted && "font-semibold text-foreground"
        )}
      >
        <span>{label}</span>
        {isSorted ? (
          sort?.direction === "asc" ? (
            <ArrowUpIcon className="size-3.5 shrink-0" />
          ) : (
            <ArrowDownIcon className="size-3.5 shrink-0" />
          )
        ) : (
          <ArrowUpDownIcon className="size-3.5 shrink-0 opacity-40" />
        )}
      </button>
    </TableHead>
  );
}

/** Employee card as a compact badge: linked or not, details on hover, click to assign. */
function EmployeeCardBadge({
  user,
  canLinkEmployee,
  onLink,
}: {
  user: CompanyUser;
  canLinkEmployee: boolean;
  onLink: () => void;
}) {
  const employee = user.linkedEmployee;
  const hint = canLinkEmployee
    ? employee
      ? "Нажмите, чтобы сменить"
      : "Нажмите, чтобы привязать"
    : null;

  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <button
            type="button"
            aria-label={
              employee
                ? `Карточка сотрудника: ${employee.fullName}`
                : "Карточка сотрудника не привязана"
            }
            onClick={canLinkEmployee ? onLink : undefined}
            className={cn(
              "inline-flex size-7 items-center justify-center rounded-md outline-none transition-colors focus-visible:ring-2 focus-visible:ring-ring",
              employee
                ? "bg-emerald-500/10 text-emerald-600 ring-1 ring-emerald-500/25 dark:text-emerald-400"
                : "text-muted-foreground/50",
              canLinkEmployee
                ? "cursor-pointer hover:ring-1 hover:ring-foreground/15"
                : "cursor-help"
            )}
          />
        }
      >
        {employee ? (
          <UserCheckIcon className="size-4" />
        ) : (
          <UnlinkIcon className="size-4" />
        )}
      </TooltipTrigger>
      <TooltipContent
        side="bottom"
        className={cn(
          "text-xs",
          employee && "max-w-56 flex-col items-stretch gap-0.5"
        )}
      >
        {employee ? (
          <>
            <span className="font-medium">{employee.fullName}</span>
            <span className="text-background/70">
              {employee.position || "Должность не указана"}
            </span>
            {hint ? <span className="text-background/60">{hint}</span> : null}
          </>
        ) : (
          <span>{hint ?? "Карточка не привязана"}</span>
        )}
      </TooltipContent>
    </Tooltip>
  );
}

function ObjectsCell({
  objectIds,
  objects,
}: {
  objectIds: string[];
  objects: { id: string; name: string }[];
}) {
  const names = userObjectNames(objectIds, objects);
  if (names.length === 0) {
    return <EmptyCell />;
  }
  const visible = names.slice(0, 2).join(", ");
  const rest = names.length - 2;
  return (
    <p className="max-w-56 truncate text-sm" title={names.join(", ")}>
      {visible}
      {rest > 0 ? ` +${rest}` : ""}
    </p>
  );
}

export function UsersList({
  users,
  objects,
  canLinkEmployee,
  canAssignObjects,
  canAssignRole,
  canChangeStatus,
  canPreferWebApp,
  sort,
  onSortChange,
  onAssign,
  onAssignRole,
  onAssignObjects,
  onChangeStatus,
}: UsersListProps) {
  return (
    <Card
      size="sm"
      className="flex min-h-0 flex-1 flex-col gap-0 overflow-hidden py-0 shadow-float"
    >
      <Table
        className="border-separate border-spacing-0"
        containerClassName="h-full min-h-0 flex-1 overflow-auto"
      >
        <TableCaption className="sr-only">Список пользователей</TableCaption>
        <TableHeader className={cn("sticky top-0 z-10", HEAD_BG)}>
          <TableRow className="border-b-0 hover:bg-transparent">
            <SortableHead
              columnKey="name"
              label="Пользователь"
              hint="По имени"
              sort={sort}
              onSortChange={onSortChange}
            />
            <SortableHead
              columnKey="role"
              label="Роль"
              hint="По названию роли"
              sort={sort}
              onSortChange={onSortChange}
            />
            <SortableHead
              columnKey="status"
              label="Статус"
              sortFirst="desc"
              hint="Сначала активные"
              sort={sort}
              onSortChange={onSortChange}
            />
            <SortableHead
              columnKey="employee"
              label="Карточка"
              sortFirst="desc"
              hint="Сначала с карточкой"
              sort={sort}
              onSortChange={onSortChange}
            />
            <SortableHead
              columnKey="objects"
              label="Объекты"
              sortFirst="desc"
              hint="По количеству объектов"
              sort={sort}
              onSortChange={onSortChange}
            />
            <SortableHead
              columnKey="web"
              label="Новая версия"
              sortFirst="desc"
              hint="Сначала включённые"
              className="text-right"
              sort={sort}
              onSortChange={onSortChange}
            />
            <TableHead className={cn(HEAD_CELL, "w-10 text-right")}>
              <span className="sr-only">Действия</span>
            </TableHead>
          </TableRow>
        </TableHeader>
        <TableBody className="[&_td]:border-b [&_td]:border-border/50 [&>tr:last-child>td]:border-b-0">
          {users.map((user) => {
            const name = userDisplayName(user);
            const phone = formatPhone(user.phone);
            // Владелец компании не может отключить сам себя.
            const showStatusAction = canChangeStatus && !user.isOwner;
            const hasActions =
              canAssignObjects || canAssignRole || showStatusAction;

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
                  <EmployeeCardBadge
                    user={user}
                    canLinkEmployee={canLinkEmployee}
                    onLink={() => onAssign(user)}
                  />
                </TableCell>
                <TableCell>
                  <ObjectsCell objectIds={user.objectIds} objects={objects} />
                </TableCell>
                <TableCell className="text-right">
                  <UserPreferWebSwitch
                    user={user}
                    canToggle={canPreferWebApp}
                  />
                </TableCell>
                <TableCell className="text-right">
                  {hasActions ? (
                    <DropdownMenu>
                      <DropdownMenuTrigger
                        render={
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon-sm"
                            className="ml-auto text-muted-foreground"
                            aria-label={`Действия: ${name}`}
                          />
                        }
                      >
                        <EllipsisIcon />
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end" className="min-w-52">
                        <DropdownMenuGroup>
                          {canAssignObjects ? (
                            <DropdownMenuItem
                              onClick={() => onAssignObjects(user)}
                            >
                              <FolderKanbanIcon />
                              Объекты
                            </DropdownMenuItem>
                          ) : null}
                          {canAssignRole ? (
                            <DropdownMenuItem onClick={() => onAssignRole(user)}>
                              <ShieldIcon />
                              Роль
                            </DropdownMenuItem>
                          ) : null}
                        </DropdownMenuGroup>
                        {showStatusAction ? (
                          <>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                              variant={user.isActive ? "destructive" : "default"}
                              onClick={() => onChangeStatus(user)}
                            >
                              {user.isActive ? <BanIcon /> : <CircleCheckIcon />}
                              {user.isActive
                                ? "Отключить доступ"
                                : "Вернуть доступ"}
                            </DropdownMenuItem>
                          </>
                        ) : null}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  ) : (
                    <EmptyCell />
                  )}
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </Card>
  );
}
