import { readFileSync } from 'node:fs';
export const fixtures = JSON.parse(readFileSync(new URL('../../contracts/fixtures/share-payload-cases.json', import.meta.url), 'utf8')).cases;
export const validPayload = () => structuredClone(fixtures[0].payload);
export const singlePayload = () => structuredClone(fixtures.find((c: any) => c.name === 'valid-single-item-no-optional-details').payload);
