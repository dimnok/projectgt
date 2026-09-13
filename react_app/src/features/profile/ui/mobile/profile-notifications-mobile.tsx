"use client";

import { useEffect, useMemo, useState } from "react";
import { BellIcon, PlusIcon, Trash2Icon } from "lucide-react";
import { toast } from "sonner";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
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
import { Switch } from "@/components/ui/switch";
import { useUpdateProfileNotifications } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";

type ProfileNotificationsMobileProps = {
  profile: CurrentProfile;
  onBack: () => void;
};

const DEFAULT_SLOTS = ["13:00", "15:00", "18:00"];

function generateTimeOptions() {
  const options: { value: string; label: string }[] = [];
  for (let h = 7; h <= 23; h++) {
    for (let m = 0; m < 60; m += 30) {
      const hh = h.toString().padStart(2, "0");
      const mm = m.toString().padStart(2, "0");
      const time = `${hh}:${mm}`;
      options.push({ value: time, label: time });
    }
  }
  return options;
}

type PushPermissionStatus = "granted" | "denied" | "default" | "unsupported";

function getPushPermission(): PushPermissionStatus {
  if (typeof window === "undefined" || !("Notification" in window)) {
    return "unsupported";
  }
  return window.Notification.permission;
}

export function ProfileNotificationsMobile({
  profile,
  onBack,
}: ProfileNotificationsMobileProps) {
  const updateNotifications = useUpdateProfileNotifications();
  const timeOptions = useMemo(() => generateTimeOptions(), []);
  const initialSlots =
    profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS;
  const initialEnabled = profile.slotTimes.length > 0;
  const [remindersEnabled, setRemindersEnabled] = useState(initialEnabled);
  const [slots, setSlots] = useState<string[]>(initialSlots);
  const [pushPermission, setPushPermission] = useState<PushPermissionStatus>(
    () => getPushPermission()
  );

  useEffect(() => {
    const hasSlots = profile.slotTimes.length > 0;
    setRemindersEnabled(hasSlots);
    if (hasSlots) {
      setSlots(profile.slotTimes);
    }
  }, [profile.slotTimes]);

  async function requestPushPermission() {
    if (typeof window === "undefined" || !("Notification" in window)) {
      toast.error("Ваш браузер не поддерживает Push-уведомления");
      return;
    }

    try {
      const result = await window.Notification.requestPermission();
      setPushPermission(result);
      if (result === "granted") {
        toast.success("Push-уведомления разрешены");
      } else if (result === "denied") {
        toast.error("Уведомления заблокированы в настройках браузера");
      }
    } catch {
      toast.error("Не удалось запросить разрешение");
    }
  }

  function handleToggleReminders(enabled: boolean) {
    setRemindersEnabled(enabled);
    const toSave = enabled ? (slots.length > 0 ? slots : DEFAULT_SLOTS) : [];
    if (enabled && slots.length === 0) {
      setSlots(DEFAULT_SLOTS);
    }

    updateNotifications.mutate(toSave, {
      onSuccess: () => {
        toast.success(
          enabled ? "Напоминания включены" : "Напоминания выключены"
        );
      },
      onError: (err) => {
        setRemindersEnabled(profile.slotTimes.length > 0);
        setSlots(
          profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS
        );
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить настройки"
        );
      },
    });
  }

  function handleSlotChange(index: number, newTime: string | null) {
    if (!newTime || newTime === slots[index]) return;
    const next = [...slots];
    next[index] = newTime;
    setSlots(next);

    updateNotifications.mutate(next, {
      onSuccess: () => {
        toast.success("Время напоминания сохранено");
      },
      onError: (err) => {
        setSlots(
          profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS
        );
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить настройки"
        );
      },
    });
  }

  function handleAddSlot() {
    if (slots.length >= 4) return;
    const last = slots[slots.length - 1] ?? "18:00";
    const next = [...slots, last];
    setSlots(next);

    updateNotifications.mutate(next, {
      onSuccess: () => {
        toast.success("Слот времени добавлен");
      },
      onError: (err) => {
        setSlots(
          profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS
        );
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить настройки"
        );
      },
    });
  }

  function handleRemoveSlot(index: number) {
    if (slots.length <= 1) return;
    const next = slots.filter((_, i) => i !== index);
    setSlots(next);

    updateNotifications.mutate(next, {
      onSuccess: () => {
        toast.success("Слот времени удален");
      },
      onError: (err) => {
        setSlots(
          profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS
        );
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить настройки"
        );
      },
    });
  }

  return (
    <ProfileMobileShell title="Уведомления" onBack={onBack}>
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-4 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-sm font-medium">Напоминания о сменах</p>
                {updateNotifications.isPending ? (
                  <Spinner className="size-3.5" />
                ) : null}
              </div>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Время оповещений о заполнении смен
              </p>
            </div>
            <Switch
              checked={remindersEnabled}
              disabled={updateNotifications.isPending}
              onCheckedChange={handleToggleReminders}
              aria-label="Включить напоминания"
            />
          </div>

          {remindersEnabled ? (
            <div className="flex flex-col gap-3">
              {slots.map((slotTime, index) => (
                <div key={index} className="flex items-center gap-2">
                  <Select
                    value={slotTime}
                    items={timeOptions}
                    disabled={updateNotifications.isPending}
                    onValueChange={(val) => handleSlotChange(index, val)}
                  >
                    <SelectTrigger className="h-11 min-w-0 flex-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="max-h-56" side="bottom" align="start">
                      <SelectGroup>
                        {timeOptions.map((opt) => (
                          <SelectItem key={opt.value} value={opt.value}>
                            {opt.label}
                          </SelectItem>
                        ))}
                      </SelectGroup>
                    </SelectContent>
                  </Select>
                  {slots.length > 1 ? (
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      disabled={updateNotifications.isPending}
                      className="size-11 shrink-0 text-muted-foreground hover:text-destructive"
                      aria-label={`Удалить слот ${index + 1}`}
                      onClick={() => handleRemoveSlot(index)}
                    >
                      <Trash2Icon />
                    </Button>
                  ) : null}
                </div>
              ))}

              {slots.length < 4 ? (
                <Button
                  type="button"
                  variant="outline"
                  size="lg"
                  className="w-full"
                  disabled={updateNotifications.isPending}
                  onClick={handleAddSlot}
                >
                  <PlusIcon data-icon="inline-start" />
                  Добавить время
                </Button>
              ) : null}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Напоминания выключены.
            </p>
          )}
        </div>

        <div className="flex flex-col gap-3 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-medium">Push на устройстве</p>
            {pushPermission === "granted" ? (
              <Badge variant="success">Разрешены</Badge>
            ) : pushPermission === "denied" ? (
              <Badge variant="destructive">Заблокированы</Badge>
            ) : pushPermission === "unsupported" ? (
              <Badge variant="outline">Нет поддержки</Badge>
            ) : (
              <Badge variant="warning">Не настроены</Badge>
            )}
          </div>
          {pushPermission === "default" ? (
            <Button
              type="button"
              variant="outline"
              size="lg"
              className="w-full"
              onClick={() => void requestPushPermission()}
            >
              <BellIcon data-icon="inline-start" />
              Разрешить уведомления
            </Button>
          ) : pushPermission === "denied" ? (
            <Alert variant="destructive">
              <AlertTitle>Уведомления заблокированы</AlertTitle>
              <AlertDescription>
                Разрешите их в настройках сайта в браузере.
              </AlertDescription>
            </Alert>
          ) : (
            <p className="text-sm text-muted-foreground">
              {pushPermission === "granted"
                ? "Устройство принимает уведомления."
                : "Этот браузер не поддерживает Web Push."}
            </p>
          )}
        </div>

        <div className="flex flex-col gap-2 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-medium">Telegram</p>
            {profile.telegramUserId ? (
              <Badge variant="success">Подключен</Badge>
            ) : (
              <Badge variant="outline">Не привязан</Badge>
            )}
          </div>
          {profile.telegramUserId ? (
            <code className="text-xs text-muted-foreground">
              ID {profile.telegramUserId}
            </code>
          ) : (
            <p className="text-sm text-muted-foreground">
              Привязка выполняется через бота компании.
            </p>
          )}
        </div>
      </div>
    </ProfileMobileShell>
  );
}
