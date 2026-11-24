const B3={m:{p:new Image(),mo:new Image()},f:{p:new Image(),mo:new Image()}};for(const g of ['m','f']){B3[g].p.src='p3d_'+g+'.png';B3[g].mo.src='m3d_'+g+'.png'}
const B3N=12,B3CIC=1.55; // 12 quadros por ciclo de 2 passos; ciclos por segundo andando (combina com a velocidade de 72)
function b3ok(im){return im.complete&&im.naturalWidth}
// o jogo dá a direção do passo NA TELA; converte para o chão antes de escolher a foto
function b3dir(sa){const sx=Math.cos(sa),sy=Math.sin(sa),dx=(sx/IA+sy/IB)/2,dy=(sy/IB-sx/IA)/2,w=Math.atan2(dy,dx)*180/Math.PI;return((Math.round((90-w)/45)%8)+8)%8}
function b3Pessoa(c,x,y,v,o){const g=v&&v.sexo===1?'f':'m',im=B3[g].p;if(!b3ok(im))return false;
 const st=v||{};let d;
 if(o.sit)d=o.frente?0:o.back?4:(o.dir>0?6:2);
 else if(o.mv!=null){d=b3dir(o.mv);st._b3d=d}
 else d=st._b3d!=null?st._b3d:0;
 const mov=o.mv!=null&&o.walk!=null&&!o.sit;
 if(mov){const t=performance.now()/1000;st._b3p=((st._b3p||0)+Math.min(.1,t-(st._b3t||t))*B3CIC)%1;st._b3t=t}else{st._b3t=null}
 const col=o.sit?13:mov?Math.floor(st._b3p*B3N)%B3N:12,k=.5*(o.s||PS)/PS;
 c.save();if(!o.sit){c.fillStyle='rgba(0,0,0,.2)';c.beginPath();c.ellipse(x,y,11*k*2,4.5*k*2,0,0,7);c.fill()}
 c.drawImage(im,col*128,d*128,128,128,x-64*k,y-102.2*k,128*k,128*k);c.restore();return true}
function b3Moto(c,x,y,v,th,ang){const g=v&&v.sexo===1?'f':'m',im=B3[g].mo;if(!b3ok(im))return false;
 const N=32,j=((Math.round((Math.PI+ang)/(Math.PI*2/N)))%N+N)%N,k=.5;
 c.drawImage(im,(j%8)*128,Math.floor(j/8)*128,128,128,x-64*k,y-102.2*k,128*k,128*k);return true}
