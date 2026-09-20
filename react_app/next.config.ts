import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import path from "node:path";
import { networkInterfaces } from "node:os";
import type { NextConfig } from "next";

const APP_VERSION = JSON.parse(
  readFileSync(path.join(__dirname, "package.json"), "utf8")
).version as string;

/**
 * Что входит в отпечаток сборки: код, статика и зависимости.
 * Список короткий намеренно — только то, что реально меняет сайт.
 */
const FINGERPRINT_TARGETS = [
  "src",
  "public",
  "package.json",
  "package-lock.json",
  "next.config.ts",
];

/** Считает отпечаток файла или папки и подмешивает его в общий хеш. */
function updateFingerprint(hash: ReturnType<typeof createHash>, target: string) {
  const full = path.join(__dirname, target);
  if (!existsSync(full)) {
    return;
  }

  if (statSync(full).isDirectory()) {
    const entries = readdirSync(full, { withFileTypes: true }).sort((a, b) =>
      a.name.localeCompare(b.name)
    );
    for (const entry of entries) {
      updateFingerprint(hash, path.join(target, entry.name));
    }
    return;
  }

  // Путь берём относительный: отпечаток не зависит от папки, где идёт сборка.
  hash.update(target);
  hash.update(readFileSync(full));
}

/** Отпечаток содержимого сайта: меняется при правках, не меняется без них. */
function contentFingerprint(): string {
  const hash = createHash("sha1");
  for (const target of FINGERPRINT_TARGETS) {
    updateFingerprint(hash, target);
  }
  return hash.digest("hex");
}

/** Коммит репозитория сайта, если хостинг передал его в переменной окружения. */
function envCommitSha(): string | undefined {
  const value = (
    process.env.REACT_COMMIT_SHA ??
    process.env.GITHUB_SHA ??
    process.env.COMMIT_SHA ??
    process.env.VCS_COMMIT_HASH
  )?.trim();
  return value || undefined;
}

/**
 * Код сборки сайта.
 *
 * По нему колокольчик в шапке понимает, что вышла новая версия: браузер
 * сравнивает код своей сборки с кодом, который отдаёт сервер. Поэтому код
 * обязан меняться при каждой правке сайта и оставаться прежним без правок.
 *
 * `git rev-parse` здесь не используется намеренно: папка `react_app` лежит
 * внутри Flutter-репозитория, и команда вернула бы коммит Flutter, а не сайта.
 * А чтение файла от предыдущей сборки возвращало бы старый код — тогда
 * обновление не находилось бы никогда.
 */
function resolveBuildId(): string {
  return envCommitSha() ?? contentFingerprint();
}

const BUILD_ID = resolveBuildId();

/** Дата и время сборки: показываем человеку, чтобы было понятно, что обновилось. */
const BUILD_TIME = new Date().toISOString();

function localIpv4Origins() {
  const origins: string[] = [];

  for (const addrs of Object.values(networkInterfaces())) {
    for (const addr of addrs ?? []) {
      if (String(addr.family) === "IPv4" && !addr.internal) {
        origins.push(addr.address);
      }
    }
  }

  return origins;
}

const nextConfig: NextConfig = {
  generateBuildId: async () => BUILD_ID,
  env: {
    NEXT_PUBLIC_APP_VERSION: APP_VERSION,
    NEXT_PUBLIC_BUILD_ID: BUILD_ID,
    NEXT_PUBLIC_BUILD_TIME: BUILD_TIME,
  },
  turbopack: {
    root: path.resolve(__dirname),
  },
  allowedDevOrigins: [
    ...new Set(["192.168.1.142", "192.168.1.111", ...localIpv4Origins()]),
  ],
  async headers() {
    return [
      {
        source: "/sw.js",
        headers: [
          {
            key: "Cache-Control",
            value: "no-store, must-revalidate",
          },
        ],
      },
    ];
  },
};

export default nextConfig;
