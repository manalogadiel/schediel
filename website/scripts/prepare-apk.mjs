import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
const input=process.argv[2];
if(!input)throw new Error('Usage: node scripts/prepare-apk.mjs <absolute path to Schediel.apk>');
const bytes=await readFile(input);
const dir=new URL('../dist/downloads/',import.meta.url);
await mkdir(dir,{recursive:true});
const parts=[];
const partSize=16*1024*1024;
for(let offset=0;offset<bytes.length;offset+=partSize){
  const file=`schediel-${parts.length+1}.part`;
  const chunk=bytes.subarray(offset,Math.min(offset+partSize,bytes.length));
  await writeFile(new URL(file,dir),chunk);
  parts.push({file,size:chunk.length});
}
const manifest={filename:'Schediel.apk',size:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),parts};
await writeFile(new URL('manifest.json',dir),JSON.stringify(manifest,null,2)+'\n');
console.log(`Prepared ${parts.length} parts, ${bytes.length} bytes. SHA-256: ${manifest.sha256}`);
