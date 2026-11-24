const B3={m:{p:new Image(),mo:new Image()},f:{p:new Image(),mo:new Image()}};for(const g of ['m','f']){B3[g].p.src='p3d_'+g+'.png';B3[g].mo.src='m3d_'+g+'.png'}
window.__MOFF=window.__MOFF||0;window.__MDIR=window.__MDIR||1;window.__MSY=window.__MSY||0;
function b3ok(im){return im.complete&&im.naturalWidth}
function b3Pessoa(c,x,y,v,o){const g=v&&v.sexo===1?'f':'m',im=B3[g].p;if(!b3ok(im))return false;
 let ang=o.mv;if(ang==null)ang=(v&&v._b3a!=null)?v._b3a:Math.PI/2;else if(v)v._b3a=ang;
 let d;if(o.mv==null&&!(v&&v._b3a!=null)){d=o.back?4:(o.lado||o.perfil)?(o.dir>0?6:2):(o.dir>0?7:1)}else d=((Math.round((90-ang*180/Math.PI)/45)%8)+8)%8;
 const mov=o.mv!=null&&o.walk!=null,col=o.sit?9:mov?Math.floor((((o.walk/(2*Math.PI))%1)+1)%1*8)%8:8,k=.5*(o.s||PS)/PS;
 c.save();if(!o.sit){c.fillStyle='rgba(0,0,0,.2)';c.beginPath();c.ellipse(x,y,11*k*2,4.5*k*2,0,0,7);c.fill()}
 c.drawImage(im,col*128,d*128,128,128,x-64*k,y-102.2*k,128*k,128*k);c.restore();return true}
function b3Moto(c,x,y,v,th,ang){const g=v&&v.sexo===1?'f':'m',im=B3[g].mo;if(!b3ok(im))return false;
 const N=32,i=((Math.round((Math.PI+ang)/(Math.PI*2/N)))%N+N)%N,j=(((i*window.__MDIR+window.__MOFF)%N)+N)%N,k=.5;
 c.drawImage(im,(j%8)*128,Math.floor(j/8)*128,128,128,x-64*k,y-102.2*k-window.__MSY,128*k,128*k);return true}
