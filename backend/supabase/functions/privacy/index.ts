import { createRuntimeHandler } from '../_shared/runtime.ts';
Deno.serve(createRuntimeHandler(Deno.env.toObject()));
