// One passive scroll listener schedules one frame. Layout is measured only
// when the viewport, fonts, or document geometry changes.
const root=document.documentElement;
const reduce=matchMedia('(prefers-reduced-motion: reduce)');
const railViewport=document.querySelector('.rail-viewport');
const track=document.querySelector('.theme-rail');
const sections=[...document.querySelectorAll('[data-motion]')];
const clamp=(n,min=0,max=1)=>Math.min(max,Math.max(min,n));
let geometry=[];
let frame=0;
let active=false;
let maxRail=0;
let railProgress=0;
let measureFrame=0;

// Retain one accessible heading while the visual words can move independently.
document.querySelectorAll('[data-split]').forEach(heading=>{
  const original=heading.innerText.replace(/\s+/g,' ').trim();
  const walker=document.createTreeWalker(heading,NodeFilter.SHOW_TEXT);
  const nodes=[];
  while(walker.nextNode())nodes.push(walker.currentNode);
  let index=0;
  nodes.forEach(node=>{
    const fragment=document.createDocumentFragment();
    node.textContent.split(/(\s+)/).forEach(part=>{
      if(!part)return;
      if(/^\s+$/.test(part))fragment.append(document.createTextNode(part));
      else{const word=document.createElement('span');word.className='word';word.textContent=part;word.style.setProperty('--word-index',index++);fragment.append(word);}
    });
    node.replaceWith(fragment);
  });
  heading.setAttribute('aria-label',original);
  [...heading.children].forEach(child=>child.setAttribute('aria-hidden','true'));
});

function measure(){
  cancelAnimationFrame(measureFrame);
  active=!reduce.matches&&innerWidth>900&&innerHeight>=850;
  root.classList.toggle('motion-ready',active);
  const y=scrollY;
  geometry=sections.map(el=>({el,kind:el.dataset.motion,top:el.getBoundingClientRect().top+y,height:el.offsetHeight}));
  maxRail=Math.max(0,track.scrollWidth-railViewport.clientWidth);
  if(active)railViewport.scrollLeft=0;
  if(!active){
    sections.forEach(el=>{['--lift','--shrink','--fade','--rail-x','--wipe','--reveal','--parallax','--card-lift'].forEach(key=>el.style.removeProperty(key));});
  }
  schedule();
}
function render(){
  frame=0;
  if(!active)return;
  const y=scrollY;
  const vh=innerHeight;
  for(const g of geometry){
    if(y+vh<g.top-150||y>g.top+g.height+150)continue;
    const p=clamp((y-g.top)/Math.max(g.height-vh,1));
    if(g.kind==='hero'){
      const progress=clamp(y/Math.max(g.height,1));
      g.el.style.setProperty('--lift',`${-45*progress}px`);
      g.el.style.setProperty('--shrink',String(1-.075*progress));
      g.el.style.setProperty('--fade',String(1-.3*progress));
    }else if(g.kind==='statement'){
      const entrance=clamp((y+vh*.6-g.top)/(vh*.6));
      const reveal=clamp(p*1.3+.1);
      g.el.style.setProperty('--wipe',`${(1-clamp(entrance*.35+p*.75))*100}%`);
      g.el.style.setProperty('--reveal',`${(1-reveal)*100}%`);
      g.el.style.setProperty('--parallax',`${(1-p)*22-11}px`);
    }else if(g.kind==='rail'){
      if(railViewport.scrollLeft)railViewport.scrollLeft=0;
      railProgress=clamp((p-.05)/.9);
      g.el.style.setProperty('--rail-x',`${-maxRail*railProgress}px`);
    }else if(g.kind==='features'){
      const travel=clamp((y+vh-g.top)/(vh+g.height));
      g.el.style.setProperty('--card-lift',`${(travel-.5)*18}px`);
    }
  }
}
function schedule(){if(!frame)frame=requestAnimationFrame(render);}
function queueMeasure(){cancelAnimationFrame(measureFrame);measureFrame=requestAnimationFrame(measure);}
addEventListener('scroll',schedule,{passive:true});
addEventListener('resize',queueMeasure,{passive:true});
reduce.addEventListener('change',queueMeasure);
document.fonts.ready.then(queueMeasure);
addEventListener('load',queueMeasure,{once:true});

function navigateRail(direction){
  const stride=track.children[0].offsetWidth+parseFloat(getComputedStyle(track).gap);
  if(active){
    const g=geometry.find(item=>item.kind==='rail');
    const next=clamp(railProgress+direction*stride/Math.max(maxRail,1));
    scrollTo({top:g.top+(next*.9+.05)*(g.height-innerHeight),behavior:'smooth'});
  }else railViewport.scrollBy({left:direction*stride,behavior:reduce.matches?'instant':'smooth'});
}
document.addEventListener('rail-step',event=>navigateRail(event.detail));
railViewport.addEventListener('keydown',event=>{
  if(event.key==='ArrowRight'||event.key==='ArrowLeft'){event.preventDefault();navigateRail(event.key==='ArrowRight'?1:-1);}
});
track.addEventListener('focusin',event=>{
  if(!active)return;
  const card=event.target.closest('.theme-poster');
  if(!card)return;
  railViewport.scrollLeft=0;
  const stride=card.offsetWidth+parseFloat(getComputedStyle(track).gap);
  const cardStart=[...track.children].indexOf(card)*stride;
  const left=cardStart-maxRail*railProgress;
  if(left>=0&&left+card.offsetWidth<=railViewport.clientWidth)return;
  const g=geometry.find(item=>item.kind==='rail');
  const target=clamp(cardStart/Math.max(maxRail,1));
  scrollTo({top:g.top+(target*.9+.05)*(g.height-innerHeight),behavior:'instant'});
});
measure();
