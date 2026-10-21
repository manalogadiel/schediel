import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const root=new URL('../dist/',import.meta.url);
const html=await readFile(new URL('index.html',root),'utf8');
const stylesheet=html.match(/<link rel="stylesheet" href="([^"]+)"/)[1];
const css=await readFile(new URL(stylesheet,root),'utf8');
const assets=[...html.matchAll(/(?:src|href)="([^"#]+)"/g)].map(m=>m[1]).filter(x=>!/^https?:/.test(x));
for(const file of new Set(assets))await stat(new URL(file,root));
for(const [,file] of css.matchAll(/url\(['"]?([^)'"\s]+)['"]?\)/g))await stat(new URL(file,root));
const manifest=JSON.parse(await readFile(new URL('downloads/manifest.json',root),'utf8'));
if(manifest.filename!=='Schediel.apk'||!html.includes('download="Schediel.apk"'))throw new Error('The download must be named Schediel.apk');
const hash=createHash('sha256');
let size=0;
for(const part of manifest.parts){const data=await readFile(new URL('downloads/'+part.file,root));if(data.length!==part.size)throw new Error('Wrong part size');hash.update(data);size+=data.length;}
if(size!==manifest.size||hash.digest('hex')!==manifest.sha256)throw new Error('APK integrity check failed');
console.log(`Verified local assets and APK integrity (${size} bytes).`);
