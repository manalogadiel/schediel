import './previews.js';
import './motion.js';

const dialog=document.querySelector('#install-dialog');
let opener;
document.querySelectorAll('.install-trigger').forEach(button=>button.addEventListener('click',()=>{opener=button;dialog.showModal();}));
document.querySelector('.dialog-close').addEventListener('click',()=>dialog.close());
dialog.addEventListener('click',event=> {if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
dialog.addEventListener('close',()=>opener?.focus({preventScroll:true}));

// Hosts can serve these small static parts without a large-file dependency.
// The downloaded APK is assembled byte-for-byte and checked before saving.
const downloadButton=document.querySelector('.download-button');
const downloadStatus=document.querySelector('.download-status');
const progress=document.querySelector('#download-progress');
const saveLink=document.querySelector('#save-apk');
let apkUrl;
downloadButton.addEventListener('click',async()=> {
  if(apkUrl){saveLink.click();return;}
  downloadButton.disabled=true;
  downloadStatus.classList.remove('error');
  downloadStatus.textContent='Preparing your download…';
  progress.hidden=false;
  progress.value=0;
  try {
    const response=await fetch('downloads/manifest.json');
    if(!response.ok)throw new Error('The download is temporarily unavailable. Please try again.');
    const manifest=await response.json();
    const chunks=[];
    let received=0;
    for(const part of manifest.parts){
      const result=await fetch(`downloads/${part.file}`);
      if(!result.ok)throw new Error('The download was interrupted. Check your connection and try again.');
      const bytes=new Uint8Array(await result.arrayBuffer());
      if(bytes.byteLength!==part.size)throw new Error('The download was incomplete. Please try again.');
      chunks.push(bytes);
      received+=bytes.byteLength;
      progress.value=Math.round(received/manifest.size*95);
      downloadStatus.textContent=`Downloading Schediel… ${Math.round(received/manifest.size*100)}%`;
    }
    if(received!==manifest.size)throw new Error('The download was incomplete. Please try again.');
    downloadStatus.textContent='Checking your download…';
    const blob=new Blob(chunks,{type:'application/vnd.android.package-archive'});
    if(!globalThis.crypto?.subtle)throw new Error('A secure connection is required to verify the APK. Open this page over HTTPS or localhost.');
    const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',await blob.arrayBuffer())),b=>b.toString(16).padStart(2,'0')).join('');
    if(hash!==manifest.sha256)throw new Error('The file could not be verified. Please try downloading again.');
    apkUrl=URL.createObjectURL(blob);
    saveLink.href=apkUrl;
    saveLink.hidden=false;
    progress.value=100;
    downloadStatus.textContent='Your APK is ready. Open Schediel.apk from Downloads to install.';
    downloadButton.querySelector('span').textContent='Download again';
    saveLink.click();
  } catch(error) {
    downloadStatus.classList.add('error');
    downloadStatus.textContent=error instanceof TypeError?'Couldn’t connect. Check your internet and try again.':error.message;
    progress.hidden=true;
    downloadButton.querySelector('span').textContent='Try again';
  } finally {downloadButton.disabled=false;}
});
fetch('downloads/manifest.json').then(r=>r.ok?r.json():null).then(manifest=>{if(manifest)document.querySelectorAll('[data-apk-size]').forEach(el=>el.textContent=`${(manifest.size/1024/1024).toFixed(1)} MB`);}).catch(()=>{});
