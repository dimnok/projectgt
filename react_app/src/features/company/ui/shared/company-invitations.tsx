"use client";

import { CheckIcon, CopyIcon, PlusIcon, XIcon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import {
  useCompanyInvitations,
  useCreateCompanyInvitation,
  useRevokeCompanyInvitation,
} from "@/features/company/hooks/use-company-invitations";
import type { CompanyInvitation } from "@/features/company/types/company.types";
import {
  formatInvitationDate,
  invitationStatus,
  invitationStatusLabels,
} from "@/features/company/utils/company-invitation";

type CompanyInvitationsProps = {
  canEdit: boolean;
};

const EXPIRY_ITEMS = [
  { value: "7", label: "7 дней" },
  { value: "14", label: "14 дней" },
  { value: "30", label: "30 дней" },
];

function statusVariant(
  status: ReturnType<typeof invitationStatus>
): "success" | "secondary" | "destructive" | "outline" {
  if (status === "active") {
    return "success";
  }
  if (status === "used") {
    return "secondary";
  }
  if (status === "revoked") {
    return "destructive";
  }
  return "outline";
}

/** Приглашения сотрудников: код, срок, отзыв. */
export function CompanyInvitations({ canEdit }: CompanyInvitationsProps) {
  const { data, isLoading, isError, error } = useCompanyInvitations();
  const createInvitation = useCreateCompanyInvitation();
  const revokeInvitation = useRevokeCompanyInvitation();
  const [expiryDays, setExpiryDays] = useState("7");
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const invitations = data ?? [];

  function handleCreate() {
    createInvitation.mutate(Number(expiryDays), {
      onSuccess: () => toast.success("Код приглашения создан"),
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось создать код"
        ),
    });
  }

  async function handleCopy(invitation: CompanyInvitation) {
    try {
      await navigator.clipboard.writeText(invitation.code);
      setCopiedId(invitation.id);
      toast.success(`Код ${invitation.code} скопирован`);
      setTimeout(() => setCopiedId(null), 2000);
    } catch {
      toast.error("Не удалось скопировать код");
    }
  }

  function handleRevoke(invitation: CompanyInvitation) {
    revokeInvitation.mutate(invitation.id, {
      onSuccess: () => toast.success("Код отозван"),
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось отозвать код"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium">Приглашения сотрудников</p>
          <p className="text-xs text-muted-foreground">
            Код действует ограниченное время и используется один раз.
          </p>
        </div>
        {canEdit ? (
          <div className="flex items-center gap-2">
            <Select
              value={expiryDays}
              items={EXPIRY_ITEMS}
              disabled={createInvitation.isPending}
              onValueChange={(value) => setExpiryDays((value as string) ?? "7")}
            >
              <SelectTrigger aria-label="Срок действия кода">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {EXPIRY_ITEMS.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
            <Button
              type="button"
              size="sm"
              disabled={createInvitation.isPending}
              onClick={handleCreate}
            >
              {createInvitation.isPending ? (
                <Spinner data-icon="inline-start" />
              ) : (
                <PlusIcon data-icon="inline-start" />
              )}
              Создать код
            </Button>
          </div>
        ) : null}
      </div>

      {isLoading ? (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Spinner /> Загрузка…
        </div>
      ) : isError ? (
        <p className="text-sm text-destructive">
          {error instanceof Error
            ? error.message
            : "Не удалось загрузить приглашения"}
        </p>
      ) : invitations.length === 0 ? (
        <div className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
          Активных кодов нет.
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {invitations.map((invitation) => {
            const status = invitationStatus(invitation);
            const active = status === "active";
            return (
              <div
                key={invitation.id}
                className="flex items-center justify-between gap-3 rounded-lg border bg-card p-3"
              >
                <div className="min-w-0">
                  <p className="font-mono text-sm font-medium tracking-wider">
                    {invitation.code}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    до {formatInvitationDate(invitation.expiresAt)}
                  </p>
                </div>
                <div className="flex shrink-0 items-center gap-1">
                  <Badge variant={statusVariant(status)}>
                    {invitationStatusLabels[status]}
                  </Badge>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon-sm"
                    aria-label="Скопировать код"
                    onClick={() => void handleCopy(invitation)}
                  >
                    {copiedId === invitation.id ? <CheckIcon /> : <CopyIcon />}
                  </Button>
                  {canEdit && active ? (
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon-sm"
                      aria-label="Отозвать код"
                      disabled={revokeInvitation.isPending}
                      onClick={() => handleRevoke(invitation)}
                    >
                      <XIcon />
                    </Button>
                  ) : null}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
