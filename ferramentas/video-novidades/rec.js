// node rec.js pasta cena  -> grava quadros e gera mp4 em pasta/out/cena.mp4
const {chromium}=require('playwright');const fs=require('fs');const [dir,cena]=process.argv.slice(2);const FPS=30,W=640,H=400;
const CENAS=require(dir+'/cenas.js');
(async()=>{const C=CENAS[cena];const b=await chromium.launch();const pg=await b.newPage({viewport:{width:W,height:H}});const er=[];pg.on('pageerror',e=>er.push(e.message));
 // o jogo precisa rodar uns segundos em tempo "real" virtual para carregar
 await pg.goto('file://'+dir+'/index.html');for(let i=0;i<40;i++){await pg.evaluate(()=>window.__step&&window.__step(50));await pg.waitForTimeout(120)}
 await pg.evaluate(()=>{const t=window.__t;t.L.me.xp=9e8;t.L.me.dinheiro=900000;t.lsave();t.est();document.querySelectorAll('.modal,.sheet').forEach(m=>m.classList.add('hidden'));document.querySelectorAll('div').forEach(e=>{if(/PRIMEIRA MISS/.test(e.textContent)&&e.children.length<6)e.remove()})});
 for(let i=0;i<10;i++){await pg.evaluate(()=>window.__step(50));await pg.waitForTimeout(60)}
 if(C.setup)await C.setup(pg);
 const out=dir+'/fr_'+cena;fs.rmSync(out,{recursive:true,force:true});fs.mkdirSync(out,{recursive:true});
 for(let f=0;f<C.frames;f++){if(C.at&&C.at[f])await C.at[f](pg);if(C.cada)await C.cada(pg,f);await pg.evaluate(()=>{const t=window.__t;if(t&&t.eu)t.eu.bub=null});await pg.evaluate(ms=>window.__step(ms),1000/FPS);await pg.screenshot({path:out+'/'+String(f).padStart(5,'0')+'.jpg',type:'jpeg',quality:88})}
 await b.close();fs.mkdirSync(dir+'/out',{recursive:true});
 require('child_process').execSync(`ffmpeg -y -loglevel error -framerate ${FPS} -i ${out}/%05d.jpg -vf "scale=${W}:${H}" -c:v libx264 -preset slow -crf 30 -pix_fmt yuv420p -movflags +faststart ${dir}/out/${cena}.mp4 && ffmpeg -y -loglevel error -i ${out}/00040.jpg -q:v 6 ${dir}/out/${cena}.jpg`);
 console.log(cena,'ok',(fs.statSync(dir+'/out/'+cena+'.mp4').size/1024|0)+'KB','erros:',er.slice(0,3))})();
