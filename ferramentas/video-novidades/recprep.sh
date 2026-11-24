# uso: recprep.sh pasta -> cópia offline para gravar vídeo (relógio controlado, sem barra de cima, com legenda)
S=/tmp/claude-0/-home-user-vila-do-tonhao/7adeacad-5df4-5fdf-9944-ee17412c5bc6/scratchpad
bash $S/prep.sh $1
python3 - $1 <<'P'
import sys;p=sys.argv[1]+'/index.html';s=open(p).read()
clock="""<script>(function(){let vt=1000;const base=Date.now()-vt;let q=[];performance.now=()=>vt;Date.now=()=>Math.round(base+vt);window.requestAnimationFrame=cb=>{q.push(cb);return q.length};window.cancelAnimationFrame=()=>{};
window.__step=ms=>{vt+=ms;const c=q;q=[];for(const f of c){try{f(vt)}catch(e){console.error(e)}}};})();</script>"""
i=s.index('<head>')+6;s=s[:i]+clock+s[i:]
css="""<style>#perto,#carBtns,#paBtns,#top,#zoom,#bottom,#mini,#painelEsq,.bannerPref,#toast,#chatPainel,#novid,#tuto,#joy{display:none!important}
#vcap{position:fixed;left:14px;bottom:14px;z-index:999;background:rgba(20,10,16,.82);color:#fff;font:700 17px Fredoka,sans-serif;padding:8px 14px;border-radius:14px;border:2px solid #ffc94a;opacity:0;transition:opacity .2s;max-width:80%}
#vcap.on{opacity:1}</style><div id="vcap"></div><script>window.__cap=t=>{const e=document.getElementById('vcap');if(!t){e.classList.remove('on');return}e.textContent=t;e.classList.add('on')}</script></body>"""
i=s.rfind('</body>');s=s[:i]+css+s[i+7:]
s=s.replace("zoom:z=>","get cam(){return cam},seguir:o=>{follow=o},PUBB,deleg,lanch,butq,merc,conc,lojaRoupa,SHOPS,abrirLugar,abrirComercio,trocaAndar,closePlace,venderHorta,zoom:z=>",1)
s=s.replace('const a=msAlvo();if(a&&a.seta)','const a=null;if(a&&a.seta)').replace('function chuvaAlvo(){','function chuvaAlvo(){return 0;')
open(p,'w').write(s)
P
