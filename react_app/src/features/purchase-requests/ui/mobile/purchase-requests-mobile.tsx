"use client";

import { useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { PlusIcon } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useObjects } from "@/features/objects/hooks/use-objects";
import {
  useCreatePurchaseRequestDraft,
  usePurchaseRequestCounts,
  usePurchaseRequests,
  usePurchaseRequestSettings,
  useUpdatePurchaseRequestDraft,
} from "@/features/purchase-requests/hooks/use-purchase-requests";
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestListFilter,
} from "@/features/purchase-requests/types/purchase-request.types";
import { isPurchaseRequestSettingsConfigured } from "@/features/purchase-requests/utils/settings";
import { purchaseRequestCountLabel } from "@/features/purchase-requests/utils/format";
import {
  isPurchaseRequestListFilter,
  LIST_LIMIT,
  PURCHASE_REQUEST_FILTER_OPTIONS,
} from "@/features/purchase-requests/utils/status";
import { PurchaseRequestDetailsMobile } from "@/features/purchase-requests/ui/mobile/purchase-request-details-mobile";
import { PurchaseRequestFormSheet } from "@/features/purchase-requests/ui/mobile/purchase-request-form-sheet";
import { PurchaseRequestsMobileList } from "@/features/purchase-requests/ui/mobile/purchase-requests-mobile-list";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";
import { AppSearchField, useAppSearch } from "@/layouts/desktop/app-search";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

/**
 * Экран «Заявки» (телефон).
 *
 * Сверху — поиск и фильтр по статусу с счётчиками, ниже — реестр карточками.
 * Клик по карточке открывает заявку на весь экран. Логика общая с настольным
 * видом: те же хуки, серверные функции и права.
 */
export function PurchaseRequestsMobile() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const { query } = useAppSearch();
  const search = useDebouncedValue(query, 300);
  const { can, isOwner } = usePermissions();

  const [filter, setFilter] = useState<PurchaseRequestListFilter>(() => {
    const fromQuery = searchParams.get("filter");
    return fromQuery && isPurchaseRequestListFilter(fromQuery) ? fromQuery : "all";
  });
  // Открытая заявка: стартовое значение — из адреса (ссылка вида ?requestId=<id>).
  const [selectedId, setSelectedId] = useState<string | null>(() =>
    searchParams.get("requestId")
  );
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<{
    request: PurchaseRequest;
    items: PurchaseRequestItem[];
  } | null>(null);

  const listQuery = usePurchaseRequests(filter, search);
  const countsQuery = usePurchaseRequestCounts(search);
  const settingsQuery = usePurchaseRequestSettings();
  const objectsQuery = useObjects({ enabled: formOpen || Boolean(editing) });
  const createDraft = useCreatePurchaseRequestDraft();
  const updateDraft = useUpdatePurchaseRequestDraft();

  const settingsConfigured = isPurchaseRequestSettingsConfigured(
    settingsQuery.data
  );
  const canCreate = can("purchase_requests", "create");
  const requests = listQuery.data ?? [];
  const isTruncated = requests.length >= LIST_LIMIT;

  /** Держит адрес в согласии с открытой заявкой: ссылку можно скопировать. */
  function syncRequestInUrl(requestId: string | null) {
    const params = new URLSearchParams(searchParams.toString());
    if (requestId) {
      params.set("requestId", requestId);
    } else {
      params.delete("requestId");
    }
    const nextQuery = params.toString();
    router.replace(nextQuery ? `${pathname}?${nextQuery}` : pathname, {
      scroll: false,
    });
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
          ? "Сначала укажите участников маршрута — на компьютере"
          : "Маршрут ещё не настроен. Обратитесь к руководителю"
      );
      return;
    }
    setEditing(null);
    setFormOpen(true);
  }

  if (selectedId) {
    return (
      <PurchaseRequestDetailsMobile
        requestId={selectedId}
        onBack={closeRequest}
        onEditDraft={(request, items) => {
          closeRequest();
          setEditing({ request, items });
          setFormOpen(true);
        }}
        onDeleted={closeRequest}
      />
    );
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title="Заявки"
          className="border-b-0"
          trailing={
            canCreate ? (
              <Button
                type="button"
                size="icon"
                className="rounded-full"
                aria-label="Новая заявка"
                onClick={handleCreateClick}
              >
                <PlusIcon />
              </Button>
            ) : undefined
          }
        />
        <div className="flex flex-col gap-2.5 px-4 pb-3">
          <AppSearchField
            placeholder="Поиск по номеру, позиции, поставщику…"
            aria-label="Поиск по заявкам"
          />
          {/* Фильтр по статусу: горизонтальная лента с счётчиками */}
          <div className="-mx-4 flex gap-1.5 overflow-x-auto px-4 pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {PURCHASE_REQUEST_FILTER_OPTIONS.map((item) => {
              const count = countsQuery.data?.[item.value];
              const isActive = filter === item.value;
              return (
                <Button
                  key={item.value}
                  type="button"
                  size="sm"
                  variant={isActive ? "default" : "outline"}
                  className="shrink-0 rounded-full"
                  onClick={() => setFilter(item.value)}
                >
                  {item.label}
                  {typeof count === "number" ? (
                    <span
                      className={
                        isActive
                          ? "ml-0.5 text-[11px] font-normal opacity-80"
                          : "ml-0.5 text-[11px] font-normal text-muted-foreground"
                      }
                    >
                      {count}
                    </span>
                  ) : null}
                </Button>
              );
            })}
          </div>
          <p className="text-xs text-muted-foreground">
            {isTruncated
              ? "Показаны первые 50 заявок. Уточните поиск."
              : `В списке ${purchaseRequestCountLabel(requests.length)}`}
          </p>
        </div>
      </header>

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <PurchaseRequestsMobileList
          requests={requests}
          isLoading={listQuery.isLoading}
          errorMessage={
            listQuery.isError
              ? listQuery.error instanceof Error
                ? listQuery.error.message
                : "Не удалось загрузить заявки"
              : undefined
          }
          emptyDescription="Создайте заявку или измените фильтр."
          onSelectRequest={(request) => openRequest(request.id)}
        />
      </div>

      <PurchaseRequestFormSheet
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
    </div>
  );
}
