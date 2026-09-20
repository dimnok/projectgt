"use client";

import { Fragment, type ReactNode } from "react";

/**
 * Ссылки в ответе помощника: `[название](адрес)` и голые адреса.
 * Показываем их кликабельными, чтобы источник открывался в новой вкладке.
 */
const LINK_PATTERN =
  /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)|(https?:\/\/[^\s<]*[^\s<.,;:!?)])/g;

type ChatMessageTextProps = {
  text: string;
};

export function ChatMessageText({ text }: ChatMessageTextProps) {
  const parts: ReactNode[] = [];
  const pattern = new RegExp(LINK_PATTERN);
  let lastIndex = 0;
  let match = pattern.exec(text);

  while (match !== null) {
    if (match.index > lastIndex) {
      parts.push(
        <Fragment key={`text-${lastIndex}`}>
          {text.slice(lastIndex, match.index)}
        </Fragment>
      );
    }

    const url = match[2] ?? match[3];
    parts.push(
      <a
        key={`link-${match.index}`}
        href={url}
        target="_blank"
        rel="noreferrer noopener"
        className="break-all underline underline-offset-2"
      >
        {match[1] ?? url}
      </a>
    );

    lastIndex = match.index + match[0].length;
    match = pattern.exec(text);
  }

  if (lastIndex < text.length) {
    parts.push(
      <Fragment key={`text-${lastIndex}`}>{text.slice(lastIndex)}</Fragment>
    );
  }

  return <>{parts}</>;
}
