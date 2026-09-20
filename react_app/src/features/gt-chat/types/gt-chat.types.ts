/** Кто написал сообщение: человек или помощник. */
export type ChatAuthorKind = "user" | "ai";

/** Вид диалога. Сейчас в работе только `ai`; остальные — на будущее. */
export type ChatThreadKind = "ai" | "direct" | "group";

export type ChatThread = {
  id: string;
  title: string | null;
  kind: ChatThreadKind;
  createdAt: string;
  lastMessageAt: string;
  messageCount: number;
  lastMessageBody: string | null;
  lastMessageAuthorKind: ChatAuthorKind | null;
};

export type ChatMessage = {
  id: string;
  authorKind: ChatAuthorKind;
  authorUserId: string | null;
  authorName: string | null;
  body: string;
  createdAt: string;
};
