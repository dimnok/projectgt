"use client";

import { PencilIcon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
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
    <div className="flex min-h-0 flex-1 flex-col">
      <MobileAppBar title="Компания" />
      <div className="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
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
          <>
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

            <Card>
              <CardHeader>
                <CardTitle>Банковские счета</CardTitle>
              </CardHeader>
              <CardContent>
                <CompanyBankAccounts canEdit={isOwner} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Лицензии и СРО</CardTitle>
              </CardHeader>
              <CardContent>
                <CompanyDocuments canEdit={isOwner} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Приглашения сотрудников</CardTitle>
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
          </>
        )}
      </div>
    </div>
  );
}
