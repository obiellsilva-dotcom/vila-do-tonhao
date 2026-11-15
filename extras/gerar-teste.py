# Gera o index-teste.html a partir do index.html oficial: entra direto, sem login, tutorial e missão.
import sys
S='./'
s=open(sys.argv[1] if len(sys.argv)>1 else '/home/user/vila-do-tonhao/index.html').read()
def r(a,b):
    global s
    assert s.count(a)==1,a[:60];s=s.replace(a,b)
r("m.carros=m.carros||[];return m}","m.carros=m.carros||[];if(!m.teste3){m.teste3=1;m.dinheiro=50000;m.carros=['moto','fusca','opala','caminhonete','esportivo','kombi_tonhao'];m.carro='kombi_tonhao';m.gasolina=60;try{lsave()}catch(e){}}m.missao=2;return m}")
r("function msAtiva(){return","function msAtiva(){return false&&")
r("eu.tutoPend=true;setTimeout(tutorial,1200)}","}")
r("async function boasVindas(){if(eu)return;","async function boasVindas(){if(eu)return;{$('join').classList.add('hidden');$('provName').value='Teste';setTimeout(()=>$('enter').click(),50);return}")
open(S+'index-teste.html','w').write(s)
open(S+'t3.html','w').write(s.replace("window.__dbg={","window.__ts=toScreen;window.__dbg={",1))
print('ok')
