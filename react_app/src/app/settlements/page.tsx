import { Suspense } from "react";

import { Loading } from "@/components/shared/loading";
import { SettlementsScreen } from "@/features/settlements/ui/settlements-screen";

/** Маршрут `/settlements`: реестр счетов и карточка счёта. */
export default function SettlementsPage() {
  return (
    <Suspense fallback={<Loading />}>
      <SettlementsScreen />
    </Suspense>
  );
}
