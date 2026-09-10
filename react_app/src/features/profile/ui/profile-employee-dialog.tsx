"use client";

import { useMemo, useState } from "react";
import { CheckIcon, SearchIcon, UserIcon } from "lucide-react";
import { toast } from "sonner";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type { Employee } from "@/features/employees/types/employee.types";
import {
  employeeFullName,
  employeeInitials,
} from "@/features/employees/utils/employee.utils";
import { useLinkProfileEmployee } from "@/features/profile/hooks/use-current-profile";
import { formatPhone } from "@/lib/utils/phone";
import { cn } from "@/lib/utils";

type ProfileEmployeeDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string;
  userName: string;
  currentEmployeeId: string | null;
  companyName: string;
};

export function ProfileEmployeeDialog({
  open,
  onOpenChange,
  userId,
  userName,
  currentEmployeeId,
  companyName,
}: ProfileEmployeeDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      {open ? (
        <ProfileEmployeeDialogBody
          key={`${userId}-${currentEmployeeId ?? "none"}`}
          userId={userId}
          userName={userName}
          currentEmployeeId={currentEmployeeId}
          companyName={companyName}
          onClose={() => onOpenChange(false)}
        />
      ) : null}
    </Dialog>
  );
}

type ProfileEmployeeDialogBodyProps = {
  userId: string;
  userName: string;
  currentEmployeeId: string | null;
  companyName: string;
  onClose: () => void;
};

function ProfileEmployeeDialogBody({
  userId,
  userName,
  currentEmployeeId,
  companyName,
  onClose,
}: ProfileEmployeeDialogBodyProps) {
  const { data: employees = [], isLoading } = useEmployees();
  const linkMutation = useLinkProfileEmployee();
  const [selectedId, setSelectedId] = useState<string | null>(currentEmployeeId);
  const [search, setSearch] = useState("");

  const filteredEmployees = useMemo(() => {
    const q = search.trim().toLowerCase();
    const queryDigits = q.replace(/\D/g, "");

    return employees.filter((emp: Employee) => {
      if (!q) return true;
      const name = employeeFullName(emp).toLowerCase();
      const pos = emp.position.toLowerCase();
      const phoneDigits = emp.phone.replace(/\D/g, "");
      return (
        name.includes(q) ||
        pos.includes(q) ||
        Boolean(queryDigits && phoneDigits.includes(queryDigits))
      );
    });
  }, [employees, search]);

  const isDirty = selectedId !== currentEmployeeId;

  function handleSave() {
    if (!isDirty) {
      onClose();
      return;
    }

    linkMutation.mutate(
      { userId, employeeId: selectedId },
      {
        onSuccess: () => {
          toast.success(
            selectedId
              ? `Карточка сотрудника привязана к «${userName}»`
              : `Привязка снята с «${userName}»`
          );
          onClose();
        },
        onError: (err) => {
          toast.error(
            err instanceof Error
              ? err.message
              : "Не удалось привязать сотрудника"
          );
        },
      }
    );
  }

  return (
    <DialogContent className="max-w-xl p-0 gap-0 overflow-hidden sm:max-w-xl">
      <DialogHeader className="p-5 pb-3">
        <DialogTitle>
          {currentEmployeeId
            ? "Сменить привязанного сотрудника"
            : "Привязать карточку сотрудника"}
        </DialogTitle>
        <DialogDescription>
          Пользователь «{userName}». Выберите штатную карточку в «{companyName}».
        </DialogDescription>
      </DialogHeader>

      <div className="px-5 pb-3">
        <div className="relative">
          <SearchIcon className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Поиск по ФИО, должности или телефону..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-8 h-9 text-sm"
            autoFocus
          />
        </div>
      </div>

      <div className="max-h-[50vh] min-h-48 overflow-y-auto px-5 py-1 divide-y divide-border/50">
        {isLoading ? (
          <div className="flex h-48 items-center justify-center">
            <Spinner className="size-6 text-primary" />
          </div>
        ) : filteredEmployees.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-48 text-center text-muted-foreground gap-2">
            <UserIcon className="size-8 stroke-[1.5] text-muted-foreground/60" />
            <p className="text-sm">Сотрудники не найдены</p>
            {search ? (
              <p className="text-xs text-muted-foreground/80">
                Попробуйте изменить поисковый запрос
              </p>
            ) : null}
          </div>
        ) : (
          filteredEmployees.map((emp) => {
            const fullName = employeeFullName(emp);
            const isSelected = selectedId === emp.id;
            const isCurrent = currentEmployeeId === emp.id;

            return (
              <button
                key={emp.id}
                type="button"
                onClick={() => setSelectedId(emp.id)}
                className={cn(
                  "w-full flex items-center gap-3 p-3 text-left transition-colors rounded-lg my-1",
                  isSelected
                    ? "bg-primary/10 ring-1 ring-primary/40 text-foreground"
                    : "hover:bg-muted/60 text-foreground"
                )}
              >
                <Avatar className="size-9 shrink-0">
                  {emp.photoUrl ? (
                    <AvatarImage src={emp.photoUrl} alt={fullName} />
                  ) : null}
                  <AvatarFallback>{employeeInitials(emp)}</AvatarFallback>
                </Avatar>

                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-medium text-sm truncate">{fullName}</p>
                    {isCurrent ? (
                      <Badge variant="outline" className="text-[10px] h-4.5 px-1.5">
                        Текущий
                      </Badge>
                    ) : null}
                  </div>

                  <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-muted-foreground mt-0.5">
                    <span>{emp.position || "Должность не указана"}</span>
                    {emp.phone ? (
                      <>
                        <span>•</span>
                        <span>{formatPhone(emp.phone)}</span>
                      </>
                    ) : null}
                  </div>
                </div>

                <div className="shrink-0 flex items-center gap-2">
                  <EmployeeStatusBadge status={emp.status} />
                  <div
                    className={cn(
                      "size-5 rounded-full border flex items-center justify-center transition-colors",
                      isSelected
                        ? "border-primary bg-primary text-primary-foreground"
                        : "border-muted-foreground/40"
                    )}
                  >
                    {isSelected ? <CheckIcon className="size-3 stroke-[3]" /> : null}
                  </div>
                </div>
              </button>
            );
          })
        )}
      </div>

      <DialogFooter className="p-4 px-5 bg-muted/30 border-t justify-between sm:justify-between items-center">
        <div>
          {selectedId ? (
            <Button
              type="button"
              variant="ghost"
              size="xs"
              className="text-muted-foreground hover:text-destructive"
              onClick={() => setSelectedId(null)}
            >
              Очистить выбор
            </Button>
          ) : null}
        </div>

        <div className="flex items-center gap-2">
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={linkMutation.isPending}
            onClick={onClose}
          >
            Отмена
          </Button>
          <Button
            type="button"
            size="sm"
            disabled={!isDirty || linkMutation.isPending}
            onClick={handleSave}
          >
            {linkMutation.isPending ? <Spinner className="size-3.5" /> : null}
            {selectedId ? "Привязать" : "Отвязать"}
          </Button>
        </div>
      </DialogFooter>
    </DialogContent>
  );
}
