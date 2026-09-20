import type {
  ChatAuthorKind,
  ChatMessage,
  ChatThread,
  ChatThreadKind,
} from "@/features/gt-chat/types/gt-chat.types";

/** Строки серверных функций приходят объектами с полями вида `author_kind`. */
function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

export function asRowList(value: unknown): Record<string, unknown>[] {
  if (Array.isArray(value)) {
    return value
      .map(asRecord)
      .filter((row): row is Record<string, unknown> => row !== null);
  }

  const single = asRecord(value);
  return single ? [single] : [];
}

function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value : null;
}

function asAuthorKind(value: unknown): ChatAuthorKind | null {
  return value === "user" || value === "ai" ? value : null;
}

function asThreadKind(value: unknown): ChatThreadKind {
  return value === "direct" || value === "group" ? value : "ai";
}

export function mapThread(row: Record<string, unknown>): ChatThread {
  return {
    id: String(row.id),
    title: asString(row.title),
    kind: asThreadKind(row.kind),
    createdAt: String(row.created_at),
    lastMessageAt: String(row.last_message_at ?? row.created_at),
    messageCount: typeof row.message_count === "number" ? row.message_count : 0,
    lastMessageBody: asString(row.last_message_body),
    lastMessageAuthorKind: asAuthorKind(row.last_message_author_kind),
  };
}

export function mapMessage(row: Record<string, unknown>): ChatMessage {
  return {
    id: String(row.id),
    authorKind: asAuthorKind(row.author_kind) ?? "user",
    authorUserId: asString(row.author_user_id),
    authorName: asString(row.author_name),
    body: String(row.body ?? ""),
    createdAt: String(row.created_at),
  };
}
