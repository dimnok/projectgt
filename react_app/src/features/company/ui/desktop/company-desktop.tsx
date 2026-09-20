"use client";

import { PencilIcon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { CompanyBankAccounts } from "@/features/company/ui/shared/company-bank-accounts";
import { CompanyDocuments } from "@/features/company/ui/shared/company-documents";
import { CompanyInvitations } from "@/features/company/ui/shared/company-invitations";
import { CompanyRequisitesDialog } from "@/features/company/ui/shared/company-requisites-dialog";
import {
  useCompanyProfile,
  useUpdateCompany,
} from "@/features/company/hooks/use-company-profile";
import type { CompanyDraft } from "@/features/company/types/company.types";
import { usePermissions } from "@/hooks/use-permissions";

export function CompanyDesktop() {
  const { data: company, isLoading, isError, error } = useCompanyProfile();
  const { isOwner } = usePermissions();
  const updateCompany = useUpdateCompany();
  const [isEditorOpen, setIsEditorOpen] = useState(false);

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        title="Не удалось загрузить компанию"
        message={error instanceof Error ? error.message : "Ошибка загрузки"}
      />
    );
  }

  if (!company) {
    return (
      <EmptyState
        title="Компания не выбрана"
        description="Выберите активную организацию в профиле."
      />
    );
  }

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
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-heading text-xl font-medium">{company.nameFull}</h1>
          <p className="text-sm text-muted-foreground">
            {company.nameShort}
            {company.inn ? ` · ИНН ${company.inn}` : ""}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant={company.isActive ? "success" : "destructive"}>
            {company.isActive ? "Активна" : "Отключена"}
          </Badge>
          {isOwner ? (
            <Button type="button" onClick={() => setIsEditorOpen(true)}>
              <PencilIcon data-icon="inline-start" />
              Изменить
            </Button>
          ) : null}
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Реквизиты</CardTitle>
          <CardDescription>
            Организация, юридические данные, налоги и руководство.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid gap-x-8 gap-y-3 sm:grid-cols-2">
          <InfoRow label="Полное наименование" value={company.nameFull} />
          <InfoRow label="Краткое наименование" value={company.nameShort} />
          <InfoRow label="ИНН" value={company.inn} />
          <InfoRow label="КПП" value={company.kpp} />
          <InfoRow label="ОГРН" value={company.ogrn} />
          <InfoRow label="ОКПО" value={company.okpo} />
          <InfoRow label="Система налогообложения" value={company.taxationSystem} />
          <InfoRow
            label="НДС"
            value={
              company.isVatPayer ? `${company.vatRate}%` : "Не плательщик"
            }
          />
          <InfoRow label="Юридический адрес" value={company.legalAddress} />
          <InfoRow label="Фактический адрес" value={company.actualAddress} />
          <InfoRow label="Руководитель" value={company.directorName} />
          <InfoRow label="Должность" value={company.directorPosition} />
          <InfoRow label="Главный бухгалтер" value={company.chiefAccountantName} />
          <InfoRow label="Телефон" value={company.phone} />
          <InfoRow label="Email" value={company.email} />
          <InfoRow label="Сайт" value={company.website} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Банковские счета</CardTitle>
          <CardDescription>
            Счета организации для расчётов и платёжных документов.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <CompanyBankAccounts canEdit={isOwner} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Лицензии и СРО</CardTitle>
          <CardDescription>
            Документы организации: лицензии, допуски СРО, сертификаты.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <CompanyDocuments canEdit={isOwner} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Приглашения сотрудников</CardTitle>
          <CardDescription>
            Коды для вступления в организацию.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <CompanyInvitations canEdit={isOwner} />
        </CardContent>
      </Card>

      <CompanyRequisitesDialog
        open={isEditorOpen}
        company={company}
        isSaving={updateCompany.isPending}
        onOpenChange={setIsEditorOpen}
        onSubmit={handleSave}
      />
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="flex min-w-0 flex-col gap-0.5">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span className="truncate text-sm">{value?.trim() || "—"}</span>
    </div>
  );
}
