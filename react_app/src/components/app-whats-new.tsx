"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { SparklesIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  formatWhatsNewDate,
  markWhatsNewSeen,
  readSeenWhatsNewIds,
  unreadWhatsNewEntries,
  WHATS_NEW_ENTRIES,
  WHATS_NEW_OPEN_EVENT,
  type WhatsNewEntry,
} from "@/config/whats-new";
import { usePermissions } from "@/hooks/use-permissions";

/** Пауза перед показом, чтобы окно не мешало первой отрисовке экрана. */
const SHOW_DELAY_MS = 700;

/**
 * Одноразовое окно «Что нового».
 *
 * Показывается после входа, если есть непрочитанные новости (все сразу, если
 * человек пропустил несколько обновлений). После закрытия отметка «прочитано»
 * остаётся в браузере, и окно больше не появляется. Пункт меню «Что нового»
 * открывает то же окно вручную — уже прочитанные новости тоже видно.
 */
export function AppWhatsNew() {
  const { can, isReady } = usePermissions();
  const [entries, setEntries] = useState<WhatsNewEntry[] | null>(null);
  const shownRef = useRef(false);

  const canReadModule = useCallback(
    (module: string) => can(module, "read"),
    [can]
  );

  useEffect(() => {
    if (!isReady || shownRef.current) {
      return;
    }
    const unread = unreadWhatsNewEntries(
      WHATS_NEW_ENTRIES,
      readSeenWhatsNewIds(),
      canReadModule
    );
    if (unread.length === 0) {
      return;
    }
    const timer = window.setTimeout(() => {
      // Если окно уже открыли вручную — не подменяем список.
      if (shownRef.current) {
        return;
      }
      shownRef.current = true;
      setEntries(unread);
    }, SHOW_DELAY_MS);
    return () => window.clearTimeout(timer);
  }, [canReadModule, isReady]);

  useEffect(() => {
    function onOpen() {
      shownRef.current = true;
      setEntries(
        WHATS_NEW_ENTRIES.filter(
          (entry) => !entry.module || canReadModule(entry.module)
        )
      );
    }
    window.addEventListener(WHATS_NEW_OPEN_EVENT, onOpen);
    return () => window.removeEventListener(WHATS_NEW_OPEN_EVENT, onOpen);
  }, [canReadModule]);

  function handleOpenChange(open: boolean) {
    if (open || !entries) {
      return;
    }
    markWhatsNewSeen(entries.map((entry) => entry.id));
    setEntries(null);
  }

  if (!entries) {
    return null;
  }

  return (
    <Dialog open onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <SparklesIcon className="size-4 text-primary" />
            Что нового
          </DialogTitle>
          <DialogDescription>
            Коротко о том, что изменилось в приложении.
          </DialogDescription>
        </DialogHeader>

        {entries.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            Пока новых изменений нет.
          </p>
        ) : (
          <div className="flex flex-col gap-4">
            {entries.map((entry) => (
              <section key={entry.id} className="flex flex-col gap-1.5">
                <p className="text-sm font-medium">{entry.title}</p>
                <p className="text-xs text-muted-foreground">
                  {formatWhatsNewDate(entry.date)}
                </p>
                <ul className="flex flex-col gap-1">
                  {entry.items.map((item) => (
                    <li key={item} className="flex gap-2 text-sm">
                      <span aria-hidden className="text-muted-foreground">
                        •
                      </span>
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        )}

        <DialogFooter>
          <Button type="button" onClick={() => handleOpenChange(false)}>
            Понятно
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
