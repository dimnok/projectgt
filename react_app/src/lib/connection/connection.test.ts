import { describe, expect, it } from "vitest";

import { isConnectionOnline } from "@/lib/connection/connection";

describe("isConnectionOnline", () => {
  it("офлайн, если браузер сообщает об отсутствии сети", () => {
    expect(isConnectionOnline(false, true)).toBe(false);
    expect(isConnectionOnline(false, false)).toBe(false);
    expect(isConnectionOnline(false, null)).toBe(false);
  });

  it("офлайн, если сервер не ответил", () => {
    expect(isConnectionOnline(true, false)).toBe(false);
  });

  it("онлайн, когда есть сеть и сервер ответил", () => {
    expect(isConnectionOnline(true, true)).toBe(true);
  });

  it("до первой проверки сервера считает соединение рабочим", () => {
    expect(isConnectionOnline(true, null)).toBe(true);
  });
});
