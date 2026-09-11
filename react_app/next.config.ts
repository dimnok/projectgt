import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { networkInterfaces } from "node:os";
import type { NextConfig } from "next";

const APP_VERSION = JSON.parse(
  readFileSync(path.join(__dirname, "package.json"), "utf8")
).version as string;

function gitCommitSha(): string | undefined {
  const fromEnv = (
    process.env.GITHUB_SHA ??
    process.env.COMMIT_SHA ??
    process.env.VCS_COMMIT_HASH
  )?.trim();
  if (fromEnv) {
    return fromEnv;
  }

  try {
    const sha = execSync("git rev-parse HEAD", {
      cwd: __dirname,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    return sha || undefined;
  } catch {
    return undefined;
  }
}

function resolveBuildId(): string {
  const sha = gitCommitSha();
  if (sha) {
    return sha;
  }

  const builtIdPath = path.join(__dirname, ".next", "BUILD_ID");
  if (existsSync(builtIdPath)) {
    const builtId = readFileSync(builtIdPath, "utf8").trim();
    if (builtId) {
      return builtId;
    }
  }

  return `dev-${APP_VERSION}`;
}

const BUILD_ID = resolveBuildId();

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
