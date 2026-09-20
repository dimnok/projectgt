import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import type { ReactNode } from "react";

import { AppProviders } from "@/app/providers";
import { AuthGate } from "@/layouts/auth-gate";
import { PwaInstallGate } from "@/layouts/pwa-install-gate";

import "@/styles/globals.css";

const inter = Inter({
  subsets: ["latin", "cyrillic"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "Стройка PRO",
  description: "Система управления проектами и сметами",
  applicationName: "Стройка PRO",
  appleWebApp: {
    capable: true,
    title: "Стройка PRO",
    statusBarStyle: "default",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#0a0a0a" },
  ],
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html
      lang="ru"
      className={`${inter.variable} h-full overflow-hidden antialiased`}
      suppressHydrationWarning
    >
      <body className="flex h-full flex-col overflow-hidden font-sans">
        <AppProviders>
          <PwaInstallGate>
            <AuthGate>{children}</AuthGate>
          </PwaInstallGate>
        </AppProviders>
      </body>
    </html>
  );
}
