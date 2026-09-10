import path from "node:path";
import { networkInterfaces } from "node:os";
import type { NextConfig } from "next";

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
  turbopack: {
    root: path.resolve(__dirname),
  },
  allowedDevOrigins: [
    ...new Set(["192.168.1.142", "192.168.1.111", ...localIpv4Origins()]),
  ],
};

export default nextConfig;
