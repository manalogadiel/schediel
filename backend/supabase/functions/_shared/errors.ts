import type { FieldError } from './validator.ts';
export class ApiError extends Error {
  code: string;
  fields?: FieldError[];
  retryAfterSeconds?: number;
  constructor(code: string, fields?: FieldError[], retryAfterSeconds?: number) {
    super(code); this.code = code; this.fields = fields; this.retryAfterSeconds = retryAfterSeconds;
  }
}
export const errors: Record<string, { status: number; message: string; retryable?: boolean }> = {
  invalid_request: { status: 400, message: 'Check the request and try again.' },
  validation_failed: { status: 422, message: 'Some shared fields are not supported or need correction.' },
  unauthenticated: { status: 401, message: 'A valid owner session is required.' },
  forbidden: { status: 403, message: 'This request is not permitted.' },
  not_found: { status: 404, message: 'This resource is not available.' },
  idempotency_key_required: { status: 400, message: 'A valid Idempotency-Key UUID is required.' },
  idempotency_mismatch: { status: 409, message: 'This request key was used for a different request.' },
  idempotency_expired: { status: 409, message: 'This request can no longer be replayed. Check your existing links before creating a new one.' },
  invalid_token: { status: 400, message: 'The link token is malformed.' },
  link_expired: { status: 410, message: 'This link has expired.' },
  link_revoked: { status: 410, message: 'This link has been revoked.' },
  unsupported_schema_version: { status: 422, message: 'This snapshot version is not supported.' },
  payload_too_large: { status: 413, message: 'Reduce the selected share to fit the size limit.' },
  unsupported_media_type: { status: 415, message: 'Send an uncompressed UTF-8 JSON request.' },
  rate_limited: { status: 429, message: 'Too many requests. Try again later.', retryable: true },
  quota_exceeded: { status: 429, message: 'The share creation limit has been reached.', retryable: true },
  scan_unavailable: { status: 503, message: 'Cloud scanning is not enabled.', retryable: false },
  service_unavailable: { status: 503, message: 'The service is unavailable. Try again later.', retryable: true },
  internal_error: { status: 500, message: 'The request could not be completed safely.', retryable: true },
};
