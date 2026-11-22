#!/usr/bin/env python3
"""Cria uma cópia de teste do jogo que roda SEM o banco (modo offline), entra sozinha com um personagem
e expõe funções em window.__t para scripts do Playwright. Uso: python3 ferramentas/teste-offline.py /pasta/saida
Depois: publicar como Artifact privado (link de teste para o dono) ou abrir no Playwright (file://.../index.html)."""
import sys,os,shutil
raiz=os.path.dirname(os.path.dirname(os.path.abspath(__file__)));out=sys.argv[1];os.makedirs(out,exist_ok=True)
s=open(os.path.join(raiz,'index.html'),encoding='utf-8').read()
s=s.replace("const ONLINE=!!(","const ONLINE=false&&!!(",1)
s=s.replace("window.__dbg={","window.__t={get parados(){return parados},workVeic:()=>$('workVeic').onclick(),iniciarTurno,aplicarEstado,carOf,say,irPara,joyV,get trabalho(){return trabalho},set trabalho(v){trabalho=v},CARS,CARS_PREMIUM,tileAt,G,showroom:()=>entrarSala(SHOW),policia:()=>{trabalho={job:'policia',inicio:Date.now()};eu.gM=1;eu.giro=true},vitrine:()=>abrirVitrine(),sinuca:()=>abrirSinuca(false),mobilia:()=>{mobCat='sala';abrirMobilia()},drawPerson,drawCarStack,tonhao,visFromName,decode,loja:k=>{lojaTab=k;abrirLoja()},moch:()=>abrirMochilaNova(),guarda:()=>abrirGuarda(),imob:()=>abrirImobiliaria(),jobs:()=>$('zjobs').onclick(),abrirPerfil:()=>verPerfil(eu),abreEst:()=>{mobCat='estilo';abrirMobilia()},provaEstilo,hour,entrarSala,houses,MOV,carregaMoveis,get eu(){return eu},get L(){return L},lsave};window.__dbg={",1)
js="""<script>
setTimeout(async()=>{try{abrirProvador()}catch(e){}document.getElementById('provName').value='Teste';document.getElementById('enter').click();
await new Promise(r=>setTimeout(r,2500));try{[...document.querySelectorAll('button')].find(b=>/Pular tutorial/.test(b.textContent)).click()}catch(e){}
const t=window.__t;t.L.me.dinheiro=200000;t.lsave()},2500);
</script></body>"""
i=s.rfind('</body>');s=s[:i]+js+s[i+7:]
open(os.path.join(out,'index.html'),'w',encoding='utf-8').write(s)
for d in ('sons','icones'):
    if not os.path.exists(os.path.join(out,d)):shutil.copytree(os.path.join(raiz,d),os.path.join(out,d))
print('Teste offline em',os.path.join(out,'index.html'))
