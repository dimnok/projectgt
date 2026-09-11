export type AppVersionInfo = {
  version: string;
  buildId: string;
};

/**
 * Version baked into the currently running client bundle.
 */
export function getClientAppVersion(): AppVersionInfo {
  return {
    version: process.env.NEXT_PUBLIC_APP_VERSION ?? "0.1.0",
    buildId: process.env.NEXT_PUBLIC_BUILD_ID ?? "",
  };
}

export function formatAppVersionLabel(version: string): string {
  return version.startsWith("v") ? version : `v${version}`;
}

/**
 * Short deploy code for support, matching a git short SHA when possible.
 */
export function formatAppBuildLabel(buildId: string): string {
  const id = buildId.trim();
  if (!id) {
    return "";
  }
  if (/^[a-f0-9]{7,40}$/i.test(id)) {
    return id.slice(0, 7);
  }
  return id;
}

export function isAppUpdateAvailable(
  current: AppVersionInfo,
  remote: AppVersionInfo | undefined
): boolean {
  const currentId = current.buildId.trim();
  const remoteId = remote?.buildId?.trim() ?? "";
  if (!currentId || !remoteId) {
    return false;
  }
  return remoteId !== currentId;
}

export function applyAppUpdate(): void {
  const nextUrl = `${window.location.pathname}${window.location.search}${window.location.hash}`;

  if ("serviceWorker" in navigator) {
    void navigator.serviceWorker.getRegistrations().then((registrations) => {
      void Promise.all(
        registrations.map((registration) => registration.update())
      ).finally(() => {
        window.location.replace(nextUrl);
      });
    });
    return;
  }

  window.location.replace(nextUrl);
}
