// Every theme preview below is an unmodified screen capture
// from the user's connected Samsung SM-A326B running Schediel build 4006.
const themes={
  lilac:{name:'Lilac',description:'Soft violet theme',swatch:'#a798df',stage:'#eae5f7'},
  clay:{name:'Clay',description:'Warm clay theme',swatch:'#bf8c6b',stage:'#ece3d9'},
  mint:{name:'Mint',description:'Soft green theme',swatch:'#82b99c',stage:'#e2ede5'},
  midnight:{name:'Midnight',description:'Dark theme',swatch:'#30374f',stage:'#e3e5ee'},
  pop:{name:'Pop',description:'Bold colors and outlined cards',swatch:'#ffd400',stage:'#f6eccd'},
  pixel:{name:'Pixel',description:'Pixel headings and square borders',swatch:'#45bc2c',stage:'#e5eae7'},
  sketch:{name:'Sketch',description:'Handwritten headings',swatch:'#f4e6a6',stage:'#eeede3'},
  custom:{name:'Custom',description:'Custom color theme',swatch:'#a798df',stage:'#eae5f7'}
};
const dialog=document.querySelector('#theme-dialog');
const status=document.querySelector('#theme-status');
const stage=document.querySelector('.theme-detail-images');
const images=[document.querySelector('#real-app-preview'),document.querySelector('#real-home-preview')];
let changeNumber=0;
let opener;
async function selectTheme(id,button){
  const theme=themes[id];
  if(!theme)return;
  const number=++changeNumber;
  opener=button;
  document.querySelector('.selected-theme-name').textContent=theme.name;
  document.querySelector('.theme-description').textContent=theme.description;
  status.textContent=`Loading ${theme.name} theme…`;
  stage.hidden=true;
  stage.setAttribute('aria-busy','true');
  if(!dialog.open)dialog.showModal();
  try{
    const loaded=await Promise.all(['app','home'].map(async kind=>{
      const image=new Image();
      image.src=`assets/screens/${kind}-${id}.png`;
      await image.decode();
      return image;
    }));
    if(number!==changeNumber)return;
    loaded.forEach((image,i)=>{images[i].src=image.src;images[i].alt=`Actual Schediel ${theme.name} ${i===0?'app':'home-screen widget'} captured on Android`;});
    stage.hidden=false;
    status.textContent=id==='midnight'?'Midnight is always dark.':'App and home-screen widget.';
    dialog.dataset.theme=id;
  }catch{
    if(number!==changeNumber)return;
    status.textContent='This preview couldn’t load. Close it and select the theme to try again.';
  }finally{if(number===changeNumber)stage.setAttribute('aria-busy','false');}
}
document.querySelectorAll('.poster-open').forEach(button=>button.addEventListener('click',()=>selectTheme(button.dataset.theme,button)));
document.querySelector('.theme-close').addEventListener('click',()=>dialog.close());
dialog.addEventListener('close',()=>{changeNumber++;opener?.focus({preventScroll:true});});
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
document.querySelectorAll('[data-rail-step]').forEach(button=>button.addEventListener('click',()=>document.dispatchEvent(new CustomEvent('rail-step',{detail:Number(button.dataset.railStep)}))));
