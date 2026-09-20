import { Suspense } from "react";

import { Loading } from "@/components/shared/loading";
import { PurchaseRequestsScreen } from "@/features/purchase-requests/ui/purchase-requests-screen";

export default function PurchaseRequestsPage() {
  return (
    <Suspense fallback={<Loading />}>
      <PurchaseRequestsScreen />
    </Suspense>
  );
}
