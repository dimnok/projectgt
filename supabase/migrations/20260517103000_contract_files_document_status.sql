-- Статус документооборота, версия и признак новой редакции для файлов договора.

ALTER TABLE public.contract_files
  ADD COLUMN IF NOT EXISTS document_status text NOT NULL DEFAULT 'draft',
  ADD COLUMN IF NOT EXISTS document_version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_amendment boolean NOT NULL DEFAULT false;

ALTER TABLE public.contract_files
  DROP CONSTRAINT IF EXISTS contract_files_document_version_chk;

ALTER TABLE public.contract_files
  ADD CONSTRAINT contract_files_document_version_chk
  CHECK (document_version >= 1);

ALTER TABLE public.contract_files
  DROP CONSTRAINT IF EXISTS contract_files_document_status_chk;

ALTER TABLE public.contract_files
  ADD CONSTRAINT contract_files_document_status_chk
  CHECK (
    document_status IN (
      'draft',
      'pending_approval',
      'approved',
      'signed',
      'rejected',
      'obsolete'
    )
  );

COMMENT ON COLUMN public.contract_files.document_status IS 'Статус: draft | pending_approval | approved | signed | rejected | obsolete';
COMMENT ON COLUMN public.contract_files.document_version IS 'Номер версии для отображения (v1, v2, …)';
COMMENT ON COLUMN public.contract_files.is_amendment IS 'Признак новой редакции (пометка «изм.» в списке)';
