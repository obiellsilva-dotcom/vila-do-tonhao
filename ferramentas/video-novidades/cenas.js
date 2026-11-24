// Vídeos curtos (5 a 6 s) das novidades: um por aba, câmera perto do personagem, sem botões na tela.
const E=(pg,fn,a)=>pg.evaluate(fn,a);
const cap=t=>pg=>E(pg,x=>window.__cap(x),t);
const anda=(x,y)=>pg=>E(pg,([x,y])=>window.__t.irPara(x*32,y*32),[x,y]);
const tp=(x,y,z)=>pg=>E(pg,([x,y,z])=>{const t=window.__t;if(t.eu.rm)t.eu.rm=null;t.tp(x,y);t.seguir(t.eu);if(z)t.zoom(z);t.cam.x=t.eu.x;t.cam.y=t.eu.y-10},[x,y,z]);
const fecha=pg=>E(pg,()=>{const t=window.__t;t.closePlace();document.querySelectorAll('.modal,.sheet').forEach(m=>m.classList.add('hidden'))});
const minhaCasa=pg=>E(pg,()=>{const t=window.__t;t.hora(10);t.L.casas={107:1};t.L.me.casa_id=107;t.L.me.carros=['fusca'];t.L.me.carro='fusca';t.lsave();t.est();t.casasInfo.set(107,{dono:t.eu.id,nome:t.eu.nome})});
const L107=pg=>E(pg,()=>{const L=window.__t.houses.find(h=>h.n===107).lote;return{dx:L.dx,fy:L.fy,gx:L.gx,vaga:L.vaga,beds:L.beds,hy:L.hy,hh:L.hh}});
const sala=pg=>E(pg,()=>{const R=window.__t.eu.rm.R;return[R.x0,R.y0]});
module.exports={
 predios:{frames:165,setup:async pg=>{await E(pg,()=>window.__t.hora(10))},at:{
  0:async pg=>{await tp(48,48.6,1.45)(pg);await anda(55,48.6)(pg);await cap('⛪ Igreja')(pg)},
  41:async pg=>{await tp(41,76.6,1.35)(pg);await anda(48,76.6)(pg);await cap('🏛️ Prefeitura')(pg)},
  82:async pg=>{await tp(62,72.6,1.4)(pg);await anda(69,72.6)(pg);await cap('🚓 Delegacia')(pg)},
  123:async pg=>{await tp(88,72.6,1.4)(pg);await anda(95,72.6)(pg);await cap('🏥 Hospital')(pg)}}},
 interiores:{frames:175,setup:async pg=>{await E(pg,()=>window.__t.hora(10))},at:{
  0:async pg=>{await E(pg,()=>{const t=window.__t;t.pub('delegacia');t.zoom(1.8)});const R=await sala(pg);await anda(R[0]+6,R[1]+4.3)(pg);await cap('💼 Pegue o emprego no balcão')(pg)},
  70:async pg=>{await E(pg,()=>{const t=window.__t;t.abrirLugar(t.deleg)})},
  105:async pg=>{await fecha(pg);await E(pg,()=>window.__t.trocaAndar());await cap('⬆️ No 2º andar: as celas')(pg)},
  108:async pg=>{const R=await sala(pg);await anda(R[0]+2,R[1]+6.4)(pg)}}},
 casa:{frames:170,setup:minhaCasa,at:{
  0:async pg=>{const L=await L107(pg);await tp(L.gx+1,L.fy+2.6,1.9)(pg);await E(pg,()=>{const t=window.__t;t.eu.driving=true;t.eu.carro='fusca'});await anda(L.vaga[0]+1,L.vaga[1]+.5)(pg);await cap('🚗 O portão abre e o carro entra na garagem')(pg)},
  100:async pg=>{const L=await L107(pg);await E(pg,([x,y])=>{const t=window.__t;t.eu.driving=false;t.tp(x,y)},[L.vaga[0]-.2,L.vaga[1]+2.2]);await anda(L.dx+.5,L.fy-1.2)(pg);await cap('🏡 Lote com muro, quintal e horta')(pg)}}},
 nobre:{frames:170,setup:async pg=>{await minhaCasa(pg);await E(pg,()=>window.__t.hora(11))},at:{
  0:async pg=>{await tp(73,-9.5,1.5)(pg);await E(pg,()=>{const t=window.__t;t.eu.driving=true;t.eu.carro='fusca'});await anda(118,-9.5)(pg);await cap('🏰 Bairro Nobre: mansões com piscina')(pg)}}},
 horta:{frames:210,setup:async pg=>{await minhaCasa(pg);await E(pg,()=>{const t=window.__t;t.L.hortas={};t.L.me.mochila={};t.lsave();t.eu.mochila={}})},at:{
  0:async pg=>{const L=await L107(pg);await tp(L.beds[1][0]+.5,L.beds[1][1]+1.4,2.2)(pg);await cap('🌱 Plante')(pg);await E(pg,()=>{const t=window.__t;t.abrirHorta(t.houses.find(h=>h.n===107),0)})},
  30:async pg=>{await E(pg,async()=>{const t=window.__t;for(const [s,p] of [[0,'tomate'],[1,'alface'],[2,'milho']])await t.api.plantar(107,s,p);await t.hortaCarregar(true);t.closePlace()});await cap('⏳ A horta cresce (até com você offline)')(pg)},
  ...Object.fromEntries([45,65,85,105].map((f,i)=>[f,async pg=>{await E(pg,async k=>{const t=window.__t,H=t.L.hortas[107];for(const s in H){const p={tomate:4,alface:2,milho:10}[H[s].planta];H[s].em=new Date(Date.now()-p*36e5*[.3,.6,.85,1.05][k]).toISOString()}t.lsave();await t.hortaCarregar(true)},i)}])),
  125:async pg=>{await cap('🧺 Colha')(pg);await E(pg,async()=>{const t=window.__t;let r;for(const s of [0,1,2])r=await t.api.colher(107,s);t.eu.mochila=r.mochila;await t.hortaCarregar(true)})},
  155:async pg=>{await tp(43.5,26.4,2.1)(pg);await anda(45.5,25.6)(pg);await cap('💰 Venda a colheita no mercadinho')(pg)},
  178:async pg=>{await E(pg,()=>{const t=window.__t;t.venderHorta();setTimeout(()=>t.closePlace(),10)})}}},
 comercio:{frames:175,setup:async pg=>{await E(pg,async()=>{const t=window.__t;t.hora(11);t.L.com=null;const api=t.api;await api.comercios();await api.comprarComercio(1);await api.comNome(1,'Burguer da Vila');await api.comRepor(1,'burger',100);await api.comRepor(1,'combo',50);await api.comRepor(1,'suco',100);t.COM.clear();const l=await api.comercios();l.forEach(c=>t.COM.set(c.id,c))})},at:{
  0:async pg=>{await tp(17,48.7,1.7)(pg);await anda(21,48.7)(pg);await cap('🏪 Compre um comércio e dê o seu nome')(pg)},
  60:async pg=>{await E(pg,()=>{const t=window.__t;t.pub('lanchonete');t.zoom(1.8)});const R=await sala(pg);await anda(R[0]+4.4,R[1]+3.7)(pg);await cap('💵 Os moradores compram e você recolhe o lucro')(pg)},
  110:async pg=>{await E(pg,()=>{const t=window.__t,c=t.L.com.find(x=>x.id===1);c.caixa=2380;c.vendas=96;t.lsave();t.COM.set(1,Object.assign({},t.COM.get(1),{caixa:2380,vendas:96}));t.abrirComercio(t.lanch)})},
  145:async pg=>{await E(pg,()=>{const b=[...document.querySelectorAll('#placeActs button')].find(x=>/Recolher/.test(x.textContent));b&&b.click()})}}},
 roupas:{frames:175,setup:async pg=>{await E(pg,()=>window.__t.hora(11))},at:{
  0:async pg=>{await E(pg,()=>{const t=window.__t;t.pub('butique');t.zoom(1.9)});const R=await sala(pg);await E(pg,([x,y])=>window.__t.tp(x,y),[R[0]+6,R[1]+5]);await anda(R[0]+7.4,R[1]+2.6)(pg);await cap('👕 Roupas que só existem na Loja da Vila')(pg)},
  ...Object.fromEntries(['Jaqueta universitária','Camisa anos 70','Kimono florido','Poncho gaúcho','Camisa com suspensório','Jaqueta bomber'].map((n,i)=>[55+i*20,async pg=>{await E(pg,i=>{const t=window.__t;t.eu.v=Object.assign({},t.eu.v,{roupa:24+i,camisa:[1,8,5,10,3,0][i]});t.zoom(2.7)},i);await cap('✨ '+n)(pg)}]))}},
 mais:{frames:175,setup:async pg=>{await E(pg,()=>window.__t.hora(11))},at:{
  0:async pg=>{await E(pg,()=>{const t=window.__t;t.pub('roupas');t.zoom(1.8)});const R=await sala(pg);await anda(R[0]+6,R[1]+3.8)(pg);await cap('👗 Loja de Roupas nova')(pg)},
  60:async pg=>{await tp(5,-12.6,1.5)(pg);await anda(12,-12.6)(pg);await cap('🏢 Prédios novos no condomínio')(pg)},
  120:async pg=>{await tp(90.5,29.6,1.8)(pg);await E(pg,()=>{const t=window.__t;t.abrirLugar(t.conc)});await cap('🚗 Emprego de vendedor consertado')(pg)}}}
};
