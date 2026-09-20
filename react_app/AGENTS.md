<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

## Проверки перед сдачей

- `npm run build` — сборка Next.js (включает проверку типов)
- `npx tsc --noEmit` — только типы
- `npm run lint` — ESLint; в проекте есть старые ошибки/предупреждения вне новых файлов, ориентируйтесь на свои файлы
- `npm test` — модульные тесты (Vitest) на чистую логику: `*.test.ts` рядом с модулем

## Заметки

- Вход, завершение профиля и онбординг: `docs/auth.md`, порядок проверок — `src/layouts/auth-gate.tsx`.
- Организация создаётся только через RPC `create_company_for_user` (миграция `supabase/migrations/20260919160000_create_company_for_user.sql`), не прямыми вставками.

