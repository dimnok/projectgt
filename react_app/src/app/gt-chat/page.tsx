import { Suspense } from "react";

import { Loading } from "@/components/shared/loading";
import { GtChatScreen } from "@/features/gt-chat/ui/gt-chat-screen";

export default function GtChatPage() {
  return (
    <Suspense fallback={<Loading />}>
      <GtChatScreen />
    </Suspense>
  );
}
