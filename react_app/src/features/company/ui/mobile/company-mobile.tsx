"use client";

import { PencilIcon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  useCompanyProfile,
  useUpdateCompany,
} from "@/features/company/hooks/use-company-profile";
import type {
  CompanyDraft,
  CompanyProfile,
} from "@/features/company/types/company.types";
import { CompanyBankAccounts } from "@/features/company/ui/shared/company-bank-accounts";
import { CompanyDocuments } from "@/features/company/ui/shared/company-documents";
import { CompanyInvitations } from "@/features/company/ui/shared/company-invitations";
import { CompanyRequisitesSheet } from "@/features/company/ui/mobile/company-requisites-sheet";
import { usePermissions } from "@/hooks/use-permissions";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

export function CompanyMobile() {
  const { data: company, isLoading, isError, error } = useCompanyProfile();
  const { isOwner } = usePermissions();
  const updateCompany = useUpdateCompany();
  const [isEditorOpen, setIsEditorOpen] = useState(false);

  function handleSave(draft: CompanyDraft) {
    updateCompany.mutate(draft, {
      onSuccess: () => {
        setIsEditorOpen(false);
        toast.success("Данные компании сохранены");
      },
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить компанию"
        ),
    });
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <MobileAppBar title="Компания" />

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        {isLoading ? (
          <Loading />
        ) : isError ? (
          <ErrorState
            title="Не удалось загрузить компанию"
            message={error instanceof Error ? error.message : "Ошибка загрузки"}
          />
        ) : !company ? (
          <EmptyState
            title="Компания не выбрана"
            description="Выберите активную организацию в профиле."
          />
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <h1 className="font-heading text-lg font-medium">
                {company.nameFull}
              </h1>
              <div className="flex items-center gap-2">
                <Badge variant={company.isActive ? "success" : "destructive"}>
                  {company.isActive ? "Активна" : "Отключена"}
                </Badge>
                {company.inn ? (
                  <span className="text-xs text-muted-foreground">
                    ИНН {company.inn}
                  </span>
                ) : null}
              </div>
              {isOwner ? (
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setIsEditorOpen(true)}
                >
                  <PencilIcon data-icon="inline-start" />
                  Изменить реквизиты
                </Button>
              ) : null}
            </div>

            <CompanyRequisites company={company} />

            <Separator />
            <CompanyBankAccounts canEdit={isOwner} />
            <Separator />
            <CompanyDocuments canEdit={isOwner} />
            <Separator />
            <CompanyInvitations canEdit={isOwner} />

            <CompanyRequisitesSheet
              open={isEditorOpen}
              company={company}
              isSaving={updateCompany.isPending}
              onOpenChange={setIsEditorOpen}
              onSubmit={handleSave}
            />
          </div>
        )}
      </div>
    </div>
  );
}

/** Реквизиты компании для чтения. Пустые поля не показываем. */
function CompanyRequisites({ company }: { company: CompanyProfile }) {
  const rows = [
    { label: "Краткое наименование", value: company.nameShort },
    { label: "КПП", value: company.kpp },
    { label: "ОГРН", value: company.ogrn },
    { label: "ОКПО", value: company.okpo },
    { label: "Система налогообложения", value: company.taxationSystem },
    {
      label: "НДС",
      value: company.isVatPayer ? `${company.vatRate}%` : "Не плательщик",
    },
    { label: "Юридический адрес", value: company.legalAddress },
    { label: "Фактический адрес", value: company.actualAddress },
    { label: "Руководитель", value: company.directorName },
    { label: "Должность", value: company.directorPosition },
    { label: "Главный бухгалтер", value: company.chiefAccountantName },
    { label: "Телефон", value: company.phone },
    { label: "Email", value: company.email },
    { label: "Сайт", value: company.website },
  ].filter((row): row is { label: string; value: string } =>
    Boolean(row.value?.trim())
  );

  return (
    <div className="rounded-lg border p-3">
      <p className="mb-2 font-medium">Реквизиты</p>
      {rows.length > 0 ? (
        <dl className="flex flex-col gap-2 text-sm">
          {rows.map((row) => (
            <div key={row.label} className="flex justify-between gap-3">
              <dt className="text-muted-foreground">{row.label}</dt>
              <dd className="min-w-0 break-words text-right">{row.value}</dd>
            </div>
          ))}
        </dl>
      ) : (
        <p className="text-sm text-muted-foreground">Реквизиты не заполнены.</p>
      )}
    </div>
  );
}
