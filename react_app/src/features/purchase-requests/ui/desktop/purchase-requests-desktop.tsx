"use client";

import { useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import {
  useCreatePurchaseRequestDraft,
  useDeletePurchaseRequestDraft,
  usePurchaseRequestCompanyUsers,
  usePurchaseRequestCounts,
  usePurchaseRequestPaidByObject,
  usePurchaseRequests,
  usePurchaseRequestSettings,
  useUpdatePurchaseRequestDraft,
  useUpsertPurchaseRequestSettings,
} from "@/features/purchase-requests/hooks/use-purchase-requests";
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestListFilter,
} from "@/features/purchase-requests/types/purchase-request.types";
import { isPurchaseRequestSettingsConfigured } from "@/features/purchase-requests/utils/settings";
import {
  isPurchaseRequestListFilter,
  LIST_LIMIT,
} from "@/features/purchase-requests/utils/status";
import { PurchaseRequestsFilters } from "@/features/purchase-requests/ui/desktop/purchase-requests-filters";
import { PurchaseRequestsList } from "@/features/purchase-requests/ui/desktop/purchase-requests-list";
import { PurchaseRequestsPaidByObjectCard } from "@/features/purchase-requests/ui/desktop/purchase-requests-paid-by-object";
import { PurchaseRequestsSummary } from "@/features/purchase-requests/ui/desktop/purchase-requests-summary";
import { PurchaseRequestDetailsDialog } from "@/features/purchase-requests/ui/shared/purchase-request-details-dialog";
import { PurchaseRequestFormDialog } from "@/features/purchase-requests/ui/shared/purchase-request-form-dialog";
import { PurchaseRequestSettingsDialog } from "@/features/purchase-requests/ui/shared/purchase-request-settings-dialog";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";
import { AppSearchField, useAppSearch } from "@/layouts/desktop/app-search";

/**
 * Экран «Заявки» (только компьютер).
 *
 * Слева — реестр заявок таблицей, справа — поиск, фильтр статуса, кнопки и сводка.
 * Подробности заявки открываются в отдельном окне по клику на строку.
 */
export function PurchaseRequestsDesktop() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const { query } = useAppSearch();
  const search = useDebouncedValue(query, 300);
  const { can, isOwner } = usePermissions();
  const { data: profile } = useCurrentProfile();
  const [filter, setFilter] = useState<PurchaseRequestListFilter>(() => {
    const fromQuery = searchParams.get("filter");
    return fromQuery && isPurchaseRequestListFilter(fromQuery) ? fromQuery : "all";
  });
  // Идентификатор открытой заявки: строка таблицы подсвечена, окно открыто.
  // Стартовое значение берём из адреса — ссылка вида ?requestId=<id> открывает заявку.
  const [selectedId, setSelectedId] = useState<string | null>(() =>
    searchParams.get("requestId")
  );
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<{
    request: PurchaseRequest;
    items: PurchaseRequestItem[];
  } | null>(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [requestToDelete, setRequestToDelete] = useState<PurchaseRequest | null>(
    null
  );

  const listQuery = usePurchaseRequests(filter, search);
  const countsQuery = usePurchaseRequestCounts(search);
  const paidByObjectQuery = usePurchaseRequestPaidByObject();
  const settingsQuery = usePurchaseRequestSettings();
  // Пользователи компании нужны только в окне настройки маршрута.
  const usersQuery = usePurchaseRequestCompanyUsers(settingsOpen);
  const objectsQuery = useObjects({ enabled: formOpen || Boolean(editing) });
  const createDraft = useCreatePurchaseRequestDraft();
  const updateDraft = useUpdatePurchaseRequestDraft();
  const deleteDraft = useDeletePurchaseRequestDraft();
  const upsertSettings = useUpsertPurchaseRequestSettings();

  const settingsConfigured = isPurchaseRequestSettingsConfigured(
    settingsQuery.data
  );
  const currentUserId = profile?.id ?? null;
  const companyId = profile?.activeMembership?.companyId ?? "";

  /** Держит адрес в согласии с открытой заявкой: ссылку можно скопировать. */
  function syncRequestInUrl(requestId: string | null) {
    const params = new URLSearchParams(searchParams.toString());
    if (requestId) {
      params.set("requestId", requestId);
    } else {
      params.delete("requestId");
    }
    const query = params.toString();
    router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false });
  }

  function openRequest(requestId: string) {
    setSelectedId(requestId);
    syncRequestInUrl(requestId);
  }

  function closeRequest() {
    setSelectedId(null);
    syncRequestInUrl(null);
  }

  function handleCreateClick() {
    if (!settingsConfigured) {
      toast.error(
        isOwner
          ? "Сначала укажите участников маршрута"
          : "Маршрут ещё не настроен. Обратитесь к руководителю"
      );
      if (isOwner) {
        setSettingsOpen(true);
      }
      return;
    }
    setEditing(null);
    setFormOpen(true);
  }

  if (listQuery.isLoading) {
    return <Loading />;
  }

  if (listQuery.isError) {
    return (
      <ErrorState
        message={
          listQuery.error instanceof Error
            ? listQuery.error.message
            : "Не удалось загрузить заявки"
        }
      />
    );
  }

  const requests = listQuery.data ?? [];

  return (
    <>
      <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
        <div className="min-w-0 w-full lg:order-1">
          {requests.length === 0 ? (
            <EmptyState
              title="Заявок нет"
              description="Создайте заявку или измените фильтр."
            />
          ) : (
            <PurchaseRequestsList
              requests={requests}
              selectedId={selectedId}
              onSelect={(request) => openRequest(request.id)}
            />
          )}
        </div>
        <aside className="order-first flex min-w-0 w-full flex-col gap-3 lg:sticky lg:top-0 lg:order-2 lg:gap-6 lg:self-start">
          <div className="flex min-w-0 flex-col gap-2">
            <AppSearchField
              variant="aside"
              placeholder="Поиск по номеру, объекту, инициатору..."
              aria-label="Поиск по заявкам"
            />
            <PurchaseRequestsFilters
              filter={filter}
              counts={countsQuery.data}
              canCreate={can("purchase_requests", "create")}
              canOpenSettings={isOwner}
              onFilterChange={setFilter}
              onCreate={handleCreateClick}
              onSettings={() => setSettingsOpen(true)}
            />
          </div>
          <PurchaseRequestsSummary
            counts={countsQuery.data}
            truncated={requests.length >= LIST_LIMIT}
            settingsReady={settingsConfigured}
          />
          <PurchaseRequestsPaidByObjectCard
            rows={paidByObjectQuery.data}
            isLoading={paidByObjectQuery.isLoading}
          />
        </aside>
      </div>
      <PurchaseRequestFormDialog
        key={editing?.request.id ?? "new"}
        open={formOpen}
        request={editing?.request}
        items={editing?.items}
        objects={objectsQuery.data ?? []}
        isSaving={createDraft.isPending || updateDraft.isPending}
        onOpenChange={(open) => {
          setFormOpen(open);
          if (!open) {
            setEditing(null);
          }
        }}
        onSubmit={(input) => {
          if (editing) {
            updateDraft.mutate(
              {
                requestId: editing.request.id,
                objectId: input.objectId,
                comment: input.comment,
                items: input.items,
              },
              {
                onSuccess: (id) => {
                  setFormOpen(false);
                  setEditing(null);
                  openRequest(id);
                  toast.success("Черновик сохранён");
                },
                onError: (error) =>
                  toast.error(
                    error instanceof Error
                      ? error.message
                      : "Не удалось сохранить заявку"
                  ),
              }
            );
            return;
          }
          createDraft.mutate(input, {
            onSuccess: (id) => {
              setFormOpen(false);
              openRequest(id);
              toast.success("Заявка создана");
            },
            onError: (error) =>
              toast.error(
                error instanceof Error
                  ? error.message
                  : "Не удалось создать заявку"
              ),
          });
        }}
      />
      <PurchaseRequestSettingsDialog
        open={settingsOpen}
        settings={settingsQuery.data}
        users={usersQuery.data ?? []}
        companyId={companyId}
        isSaving={upsertSettings.isPending}
        isLoading={settingsQuery.isLoading || usersQuery.isLoading}
        onOpenChange={setSettingsOpen}
        onSubmit={(settings) => {
          upsertSettings.mutate(settings, {
            onSuccess: () => {
              setSettingsOpen(false);
              toast.success("Маршрут сохранён");
            },
            onError: (error) =>
              toast.error(
                error instanceof Error
                  ? error.message
                  : "Не удалось сохранить настройки"
              ),
          });
        }}
      />
      <PurchaseRequestDetailsDialog
        requestId={selectedId}
        currentUserId={currentUserId}
        can={can}
        settings={settingsQuery.data}
        onOpenChange={(open) => {
          if (!open) {
            closeRequest();
          }
        }}
        onEditDraft={(request, items) => {
          // Окно подробностей закрываем, чтобы не открывать два окна друг на друге.
          closeRequest();
          setEditing({ request, items });
          setFormOpen(true);
        }}
        onDeleteDraft={(request) => {
          closeRequest();
          setRequestToDelete(request);
        }}
      />
      <Dialog
        open={Boolean(requestToDelete)}
        onOpenChange={(open) => {
          if (!open) {
            setRequestToDelete(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Удалить черновик?</DialogTitle>
            <DialogDescription>
              {requestToDelete
                ? `Заявка ${requestToDelete.number} будет удалена.`
                : ""}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setRequestToDelete(null)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={deleteDraft.isPending}
              onClick={() => {
                if (!requestToDelete) {
                  return;
                }
                deleteDraft.mutate(requestToDelete.id, {
                  onSuccess: () => {
                    // Окно заявки уже закрыто перед удалением — адрес тоже очищен.
                    setRequestToDelete(null);
                    toast.success("Черновик удалён");
                  },
                  onError: (error) =>
                    toast.error(
                      error instanceof Error
                        ? error.message
                        : "Не удалось удалить заявку"
                    ),
                });
              }}
            >
              {deleteDraft.isPending ? <Spinner data-icon="inline-start" /> : null}
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
