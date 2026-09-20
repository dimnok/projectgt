"use client";

import { useEffect, useMemo, useState } from "react";
import {
  BellIcon,
  BellRingIcon,
  CheckCircle2Icon,
  ClockIcon,
  PlusIcon,
  SendIcon,
  Trash2Icon,
  XCircleIcon,
} from "lucide-react";
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

type ProfileNotificationsTabProps = {
  profile: CurrentProfile;
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

type PushPermissionStatus =
  | "granted"
  | "denied"
  | "default"
  | "unsupported";

function getPushPermission(): PushPermissionStatus {
  if (typeof window === "undefined" || !("Notification" in window)) {
    return "unsupported";
  }
  return window.Notification.permission;
}

export function ProfileNotificationsTab({
  profile,
}: ProfileNotificationsTabProps) {
  const updateNotifications = useUpdateProfileNotifications();
  const timeOptions = useMemo(() => generateTimeOptions(), []);

  // Напоминания по сменам (slot_times)
  const initialSlots = profile.slotTimes.length > 0 ? profile.slotTimes : DEFAULT_SLOTS;
  const initialEnabled = profile.slotTimes.length > 0;

  const [remindersEnabled, setRemindersEnabled] = useState(initialEnabled);
  const [slots, setSlots] = useState<string[]>(initialSlots);

  // Браузерные Push-уведомления
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
    <div className="flex flex-col gap-6">
      {/* 1. Напоминания по сменам (slot_times) */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <ClockIcon className="size-4 text-primary" />
              <CardTitle>Напоминания о сменах</CardTitle>
              {updateNotifications.isPending ? (
                <Spinner className="size-3.5" />
              ) : null}
            </div>
            <Switch
              checked={remindersEnabled}
              disabled={updateNotifications.isPending}
              onCheckedChange={handleToggleReminders}
              aria-label="Включить напоминания"
            />
          </div>
          <CardDescription>
            Время, в которое система напоминает заполнять и закрывать рабочие смены
            на объектах.
          </CardDescription>
        </CardHeader>

        <CardContent className="flex flex-col gap-4">
          {remindersEnabled ? (
            <div className="flex flex-col gap-3">
              <p className="text-xs font-medium text-muted-foreground">
                Слоты времени отправки напоминаний:
              </p>

              <div className="flex flex-col gap-2.5">
                {slots.map((slotTime, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between gap-3 rounded-lg border bg-muted/30 p-2.5 sm:justify-start"
                  >
                    <span className="text-xs font-medium text-muted-foreground w-16">
                      Слот {index + 1}:
                    </span>

                    <div className="w-32">
                      <Select
                        value={slotTime}
                        items={timeOptions}
                        disabled={updateNotifications.isPending}
                        onValueChange={(val) => handleSlotChange(index, val)}
                      >
                        <SelectTrigger className="h-8 bg-card text-xs">
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
                    </div>

                    {slots.length > 1 ? (
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon-xs"
                        disabled={updateNotifications.isPending}
                        className="text-muted-foreground hover:text-destructive"
                        aria-label={`Удалить слот ${index + 1}`}
                        onClick={() => handleRemoveSlot(index)}
                      >
                        <Trash2Icon className="size-3.5" />
                      </Button>
                    ) : null}
                  </div>
                ))}
              </div>

              {slots.length < 4 ? (
                <Button
                  type="button"
                  variant="outline"
                  size="xs"
                  disabled={updateNotifications.isPending}
                  className="w-fit gap-1 self-start mt-1"
                  onClick={handleAddSlot}
                >
                  <PlusIcon className="size-3" />
                  <span>Добавить слот времени</span>
                </Button>
              ) : null}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Напоминания о сменах сейчас отключены. Включите переключатель,
              чтобы настроить время оповещений.
            </p>
          )}
        </CardContent>
      </Card>

      {/* 2. Браузерные Push-уведомления */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <BellRingIcon className="size-4 text-primary" />
              <CardTitle>Push-уведомления устройства</CardTitle>
            </div>
            {pushPermission === "granted" ? (
              <Badge variant="success" className="gap-1">
                <CheckCircle2Icon className="size-3" />
                Разрешены
              </Badge>
            ) : pushPermission === "denied" ? (
              <Badge variant="destructive" className="gap-1">
                <XCircleIcon className="size-3" />
                Заблокированы
              </Badge>
            ) : pushPermission === "unsupported" ? (
              <Badge variant="outline">Не поддерживаются</Badge>
            ) : (
              <Badge variant="warning">Не настроены</Badge>
            )}
          </div>
          <CardDescription>
            Оперативные уведомления на рабочем столе или смартфоне при открытии и
            закрытии смен, согласовании заявок и важных событиях.
          </CardDescription>
        </CardHeader>

        <CardContent className="flex flex-col gap-3">
          {pushPermission === "granted" ? (
            <p className="text-sm text-muted-foreground">
              Браузер успешно принимает push-уведомления для текущей учетной записи.
            </p>
          ) : pushPermission === "denied" ? (
            <p className="text-sm text-destructive">
              Уведомления заблокированы в настройках этого браузера. Чтобы их
              включить, откройте настройки сайта в адресной строке и разрешите
              уведомления.
            </p>
          ) : pushPermission === "unsupported" ? (
            <p className="text-sm text-muted-foreground">
              Текущий браузер не поддерживает стандарт Web Push Notifications.
            </p>
          ) : (
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm text-muted-foreground">
                Разрешите отправку уведомлений, чтобы не пропускать важные
                изменения на объектах.
              </p>
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="self-start sm:self-auto gap-1.5"
                onClick={() => void requestPushPermission()}
              >
                <BellIcon className="size-3.5" />
                <span>Разрешить уведомления</span>
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* 3. Telegram-уведомления */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <SendIcon className="size-4 text-primary" />
              <CardTitle>Telegram-оповещения</CardTitle>
            </div>
            {profile.telegramUserId ? (
              <Badge variant="success" className="gap-1">
                <CheckCircle2Icon className="size-3" />
                Подключен
              </Badge>
            ) : (
              <Badge variant="outline">Не привязан</Badge>
            )}
          </div>
          <CardDescription>
            Бот Стройка PRO мгновенно информирует руководство и прорабов о статусе
            работ.
          </CardDescription>
        </CardHeader>

        <CardContent className="flex flex-col gap-2">
          {profile.telegramUserId ? (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>Привязанный Telegram ID:</span>
              <code className="rounded bg-muted px-2 py-0.5 font-mono text-xs text-foreground">
                {profile.telegramUserId}
              </code>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Ваш профиль пока не привязан к Telegram-боту. Привязка выполняется
              через мобильное приложение или при первом обращении к боту компании.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
