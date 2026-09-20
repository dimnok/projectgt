import { readFile } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";

import type { AppVersionInfo } from "@/lib/app-version";

export const dynamic = "force-dynamic";

async function readDeployedBuildId(): Promise<string> {
  try {
    const file = await readFile(
      path.join(process.cwd(), ".next", "BUILD_ID"),
      "utf8"
    );
    const id = file.trim();
    if (id) {
      return id;
    }
  } catch {
    // Dev server may not write BUILD_ID.
  }

  return process.env.NEXT_PUBLIC_BUILD_ID ?? "";
}

export async function GET() {
  const fromEnv = process.env.NEXT_PUBLIC_BUILD_ID ?? "";
  const payload: AppVersionInfo = {
    version: process.env.NEXT_PUBLIC_APP_VERSION ?? "0.1.0",
    buildId:
      process.env.NODE_ENV === "production"
        ? await readDeployedBuildId()
        : fromEnv,
    builtAt: process.env.NEXT_PUBLIC_BUILD_TIME ?? "",
  };

  return NextResponse.json(payload, {
    headers: {
      "Cache-Control": "no-store, must-revalidate",
    },
  });
}
