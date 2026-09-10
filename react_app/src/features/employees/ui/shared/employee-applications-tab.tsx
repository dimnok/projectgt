"use client";

import { useQuery } from "@tanstack/react-query";
import {
  CalendarDaysIcon,
  DownloadIcon,
  FileCheck2Icon,
  FileTextIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { getRequiredClient } from "@/lib/supabase/client";
import { getEmployeeApplications } from "@/features/employees/api/get-employee-applications";
import type { Employee } from "@/features/employees/types/employee.types";
import { formatRuDate } from "@/features/employees/utils/employee.utils";

type EmployeeApplicationsTabProps = {
  employee: Employee;
  canManage: boolean;
};

function applicationTypeInfo(type: string): { label: string; badgeVariant: "default" | "secondary" | "destructive" | "warning" } {
  switch (type) {
    case "vacation":
      return { label: "Оплачиваемый отпуск", badgeVariant: "default" };
    case "unpaid_leave":
      return { label: "Отпуск без содержания", badgeVariant: "secondary" };
    case "resignation":
      return { label: "Увольнение по собственному желанию", badgeVariant: "destructive" };
    default:
      return { label: type, badgeVariant: "secondary" };
  }
}

export function EmployeeApplicationsTab({
  employee,
}: EmployeeApplicationsTabProps) {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ["employee-applications", employee.id],
    queryFn: () => getEmployeeApplications(employee.id),
  });

  const applications = data ?? [];

  const handleDownloadScan = async (scanPath: string, fileName: string) => {
    try {
      const client = getRequiredClient();
      const { data: signedData, error: signError } = await client.storage
        .from("employee_applications")
        .createSignedUrl(scanPath, 60);

      if (signError || !signedData?.signedUrl) {
        throw new Error(signError?.message || "Не удалось получить файл");
      }

      const res = await fetch(signedData.signedUrl);
      const blob = await res.blob();
      const blobUrl = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = blobUrl;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(blobUrl);
    } catch {
      toast.error("Не удалось скачать скан заявления");
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h3 className="text-base font-bold tracking-tight text-foreground">
          Заявления сотрудника
        </h3>
        <p className="text-xs text-muted-foreground">
          Официальные подписанные сканы заявлений (на отпуск, отпуск без содержания, увольнение)
        </p>
      </div>

      {isLoading ? (
        <div className="flex min-h-48 items-center justify-center">
          <Spinner className="size-6 text-primary" />
        </div>
      ) : isError ? (
        <div className="rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-center text-sm text-destructive">
          {error instanceof Error ? error.message : "Не удалось загрузить заявления"}
        </div>
      ) : applications.length === 0 ? (
        <div className="flex min-h-48 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-border p-8 text-center">
          <div className="flex size-10 items-center justify-center rounded-xl bg-muted text-muted-foreground">
            <FileTextIcon className="size-5" />
          </div>
          <p className="text-sm font-semibold text-foreground">
            Заявлений пока нет
          </p>
          <p className="max-w-sm text-xs text-muted-foreground">
            Подписанные сканы документов по отпускам и кадровым изменениям
            прикрепляются в карточке сотрудника.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {applications.map((app) => {
            const info = applicationTypeInfo(app.applicationType);
            return (
              <div
                key={app.id}
                className="flex flex-col justify-between gap-3 rounded-xl border border-border/70 bg-card p-4 transition-all hover:border-border hover:shadow-2xs sm:flex-row sm:items-center"
              >
                <div className="flex min-w-0 items-start gap-3">
                  <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/5 text-primary dark:bg-primary/10">
                    <FileCheck2Icon className="size-4" />
                  </div>

                  <div className="flex min-w-0 flex-col gap-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm font-semibold text-foreground">
                        {info.label}
                      </span>
                      <Badge variant={info.badgeVariant} className="text-[11px] h-4.5">
                        {app.durationDays} дн.
                      </Badge>
                    </div>

                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <CalendarDaysIcon className="size-3 text-muted-foreground shrink-0" />
                        <span>
                          Период: {formatRuDate(app.startDate)}
                          {app.endDate ? ` — ${formatRuDate(app.endDate)}` : ""}
                        </span>
                      </div>
                      <span>Загружено: {formatRuDate(app.createdAt)}</span>
                      <span>Файл: {app.scanName}</span>
                    </div>
                  </div>
                </div>

                <div className="flex shrink-0 items-center gap-2 self-end sm:self-auto">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="gap-1.5"
                    onClick={() => handleDownloadScan(app.scanPath, app.scanName)}
                  >
                    <DownloadIcon className="size-3.5" />
                    <span>Скачать скан</span>
                  </Button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
