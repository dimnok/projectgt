import { networkInterfaces } from "node:os";
import type { NextConfig } from "next";

function localIpv4Origins() {
  const origins: string[] = [];

  for (const addrs of Object.values(networkInterfaces())) {
    for (const addr of addrs ?? []) {
      const isV4 = addr.family === "IPv4" || addr.family === 4;
      if (isV4 && !addr.internal) {
        origins.push(addr.address);
      }
    }
  }

  return origins;
}

const nextConfig: NextConfig = {
  allowedDevOrigins: [
    ...new Set(["192.168.1.142", "192.168.1.111", ...localIpv4Origins()]),
  ],
};

export default nextConfig;
