# Cidade do Tonhão — passagem para um chat novo (atualizado em 18/11/2026, fim da sessão)

> **Cole este arquivo no começo do chat novo** e anexe o `pacote-novo-chat.zip` (ou, se não der, os arquivos soltos listados na seção 2).
> Pedido ao assistente: o dono **não é programador**, usa **só o celular** e tem **pouco limite de uso**. Responda em **português do Brasil, simples, passo a passo e curto**. Edite pontos específicos, não reescreva arquivos inteiros. Antes de mandar `site.zip`, mande **foto + link de teste** para ele aprovar. Pesquise na internet quando tiver dúvida (ele pede).

---


## 0. ⚠️ TRABALHO EM ANDAMENTO (leia antes de tudo) — versão `v20261124a`, AINDA NÃO PUBLICADA
> No ar: **v20261123c** = v20261123b + correção do botão de fechar do Passe (× por cima da faixa e botão "⬅️ Voltar"). Essa correção também já está no index.html em andamento.
O `index.html` do pacote já tem estas mudanças (commitadas no ramo `ccr-e8b9720b-5amd2g`), mas **não foram testadas no navegador nem enviadas como site.zip**. O site no ar está na `v20261123b`.

### 0.1 Concessionária nova (feita, mas o dono pediu ajustes — ver 0.3)
- **Casa 59 removida** (`HOUSE_OFF.add(58)` logo depois da criação de `HOUSE_OFF`). ⚠️ Se alguém já tinha comprado a casa 59 no banco, ela some do mapa: conferir no Supabase (`select dono from casas where id=59`) e, se tiver dono, devolver o dinheiro ou trocar a casa.
- Prédio: `conc=addB({kind:'concessionaria',x:85,y:15,w:10,h:5,front:[90,20]})`. Pátio de asfalto `y20..28, x85..94` (tiles `G.ROAD`), muros laterais nas colunas 85 e 94, muro da frente na linha 28 com **portão nas colunas 89–90**, carros do pátio bloqueiam o tile.
- `CONC={X0:85,X1:95,Y0:15,Y1:20,P1:29,dentro:[kombi_tonhao,gto,neon],fora:[caminhonete,jipe,esportivo,sedan,opala,fusca,moto]}` com posição e ângulo de cada carro.
- Desenho próprio em `concIso(list)` (chamado no laço de prédios do `drawCena` no lugar de `predioFatias` quando `b.kind==='concessionaria'`): piso, faixas das vagas, parede do fundo com escritório, mesa do vendedor, plantas, carros do Pix dentro com plaquinha, fachada de vidro com colunas e letreiro "CARROS DO ZÉ", carros do pátio com plaquinha de nome e preço (`placaCarro`), muros, pilares do portão e totem. `FOCUS.concessionaria=[90,22,1.25]`.
- Plaquinha da **Lambordini (`neon`) mostra "👑 VIP"** (ela é do VIP, NÃO do Pix). Caminhonete do Tonhão e Ferrarini = "💎 Pix".

### 0.2 Tour obrigatório pela cidade (feito, NÃO testado)
- `tourCidade(forcar)` + lista `TOUR` (11 paradas: Bar, Centro de Empregos, Loja de Roupas, Concessionária, Posto/Oficina, Casas à venda, Imobiliária, Condomínio, Delegacia, Hospital, Prefeitura), câmera desliza (1,6 s) e para (3,4 s) com quadro explicando; tela bloqueada, sem botão de pular (o dono quer obrigatório). 1 vez por pessoa (`localStorage cidadeTonhao.tour.<id>`).
- Dispara: 3,2 s depois do bônus da **missão 1** (`msPasso(1)`), ao tocar em **Pular** no tutorial (`tutoPular`) e ao **pular a missão** (`msX`).
- Testar: as coordenadas de "Casas à venda" `[92,40]` e do condomínio `[15,-11]` podem precisar de ajuste; conferir que `follow` volta para o jogador e que nada fica travado.

### 0.3 O QUE O DONO PEDIU E AINDA FALTA FAZER (prioridade máxima)
1. **Fechar o showroom por fora**: o prédio da concessionária (x85–94, y15–19) vira um **prédio fechado** com telhado, fachada bonita (vidro escuro/espelhado, não transparente), letreiro e **uma porta dupla de vidro decente** (ele achou a porta atual feia). **Tirar os carros de dentro do desenho externo** (eles ficavam "abertos" e a casa 61 de trás tampava a Lambordini — "muito estranho").
2. **Showroom em OUTRA DIMENSÃO** (igual à imobiliária): criar `SALAS.show` num canto livre (sugestão `x0:-19,y0:80,x1:-7,y1:86,porta:[-13,87]`, piso porcelanato claro, parede `#eef1f5`; conferir que não bate em `mansao2` que fica em y92–98) e um objeto `SHOW={n:'show',kind:'show',front:[90,20],fixos:[mesa do vendedor, cadeiras, sofá de espera, estantes, plantas, tapete…]}` (móveis do `MOV`). Ajustar `salaDe` (`kind==='show'`→`SALAS.show`) e `salaNome` ("🚗 Showroom Carros do Zé"). Perto da porta (`conc.front`): botão **"🚗 Entrar no showroom"** → `entrarSala(SHOW)` (ver como `perto(imob.front…)` faz). Dentro: desenhar os 3 carros (Caminhonete do Tonhão 💎 Pix, Ferrarini 💎 Pix, Lambordini 👑 VIP) em discos de exposição com plaquinha (chamar de dentro do `salaItens` quando `R===SALAS.show`), e em `salaOpcoes` um botão **"🚗 Ver e comprar carros"** → `abrirLugar(conc)` (loja normal da concessionária; no app o Pix fica escondido por `NO_APP`). "Programar a área para ser mobiliada" = móveis fixos bonitos (não é para o jogador decorar).
3. **Pátio sem grama**: os tiles com muro/carro (`G.BLD`) aparecem verdes. Pintar asfalto `#3d3c44` sobre todo o retângulo `T(85)..T(95) × T(20)..T(29)` no item de piso (antes das faixas).
4. **Sedã tampado pela cobertura do posto**: mudar os carros do lado direito para a **fileira da frente** (y≈25,5), longe da cobertura. Sugestão: `fora=[['caminhonete',86.3,22.1],['jipe',87.8,22.1],['opala',86.3,25.5],['fusca',87.8,25.5],['esportivo',92.1,25.5],['sedan',93.5,25.5],['moto',91.8,22.3]]` (ângulo 1.57) e testar em print.
5. Testar tudo com print (de dia e de noite, zoom 1,5), trocar `VERSAO_JOGO`, gerar `site.zip` + `index.html`, mandar foto + link de teste para o dono aprovar.
6. Atualizar a tela de novidades (`NOV_SLIDES`/`NOVID`) com "Concessionária nova" e o tour.

### 0.4 Como gerar o site.zip
Pasta com: `index.html`, `privacidade.html`, `excluir-conta.html`, `manifest.webmanifest`, `icones/`, `.well-known/assetlinks.json`, `musicas/` (charrete.mp3, futilidades-entre-nos.mp3, o-campeao.mp3) e `sons/` (diesel, esportivo, fusca, gto, moto, neon, opala, sedan .mp3). Os mp3 estão no GitHub (pastas `musicas/` e `sons/`). Zipar a partir de dentro da pasta.

## 1. O que é o jogo
Jogo online de navegador (um único `index.html`, canvas 2D em visão **isométrica 2.5D**) de uma cidadezinha brasileira com o **Bar do Tonhão**. Personagens customizáveis, empregos com minijogos, fome/sede, XP e nível (até 50), casas e apartamentos (comprar/alugar), carros 3D (fotos de 32 ângulos), chat por salas (50 por sala, até 60 salas), sinuca, VIP, loja Pix, pets, perfil social, passe de temporada, prefeito.

## 2. Onde está cada coisa
| Peça | Onde / como |
|---|---|
| **Site** | https://viladotonhao.com.br — Cloudflare Workers (arquivos estáticos) |
| **Subir o site** | Cloudflare → Workers & Pages → `viladotonhao` → **New deployment** → enviar `site.zip` |
| **O que vai no `site.zip`** | `index.html`, `privacidade.html`, `excluir-conta.html`, `manifest.webmanifest`, pasta `icones/`, pasta `.well-known/` (assetlinks do app), pasta `musicas/` (3 mp3), pasta `sons/` (8 mp3 de motor). **Sempre subir o zip**, o index sozinho não leva sons/ícones/páginas |
| **Banco** | Supabase, projeto ref `fyviodritpungccrohvd`, plano **Free** |
| **SQL** | `banco.sql` = banco **completo** (pode rodar de novo sem perder dados). `novidades.sql` = só a última etapa. Pelo celular o editor trava com arquivo grande: **dividir em partes de ~6,5 mil letras** (ver `sql-celular/`) |
| **Pagamento** | Mercado Pago (API de Orders, Pix), Edge Function `pix` no Supabase (arquivo `pix-funcao.ts`). Preço vem da tabela `produtos`. O webhook não confia no aviso: confere no Mercado Pago |
| **Repositório** | GitHub `obiellsilva-dotcom/vila-do-tonhao`, ramo atual **`ccr-e8b9720b-5amd2g`** (tudo commitado) |
| **Link de teste** | https://claude.ai/artifact/C4QSmTKE8EojyVzA72WX4d (artifact privado da conta antiga; cópia offline com nível 30, R$ 300 mil, VIP, todos os carros, botão "🧪 Carros"). **Na conta nova crie outro**: copie o index trocando `const ONLINE=!!(` por `const ONLINE=false&&!!(` e inserindo antes de `window.__dbg={` o bloco "trapaça" (ver seção 9) |
| **E-mails** | Conta Google Play Console: **obiellsilva@gmail.com** (conta de desenvolvedor pessoal, criada em 17/11/2026, em análise). Admin do jogo = coluna `moradores.admin` (marcada direto no banco) |

### Arquivos para anexar no chat novo
`LEIA-PRIMEIRO.md` (este), `index.html`, `banco.sql`, `novidades.sql`, `pix-funcao.ts`, `GUIA-PLAY-STORE.md`, pasta `tempo-real/` (servidor Cloudflare), `CONTEXTO.md` (histórico antigo, opcional). Tudo isso está no `pacote-novo-chat.zip`.

**NÃO mande para ninguém**: `cidade-do-tonhao.keystore` e `senha-da-chave.txt` (chave do app Android). Guarde em 2 lugares (Drive + pendrive). Sem ela não dá para atualizar o app nunca mais.

## 3. Situação AGORA (18/11/2026)
- **Versão do jogo:** no ar `v20261123c`; em andamento `v20261124a` (seção 0) (trocar a cada versão nova: o jogo avisa "🆕 Atualização").
- **Banco:** o dono rodou **todas as etapas até a 28** (a 28 em 4 partes). Nada pendente de SQL.
- **Site:** confirmar se ele subiu o `site.zip` **v20261123b** (a última). Se não, mandar subir.
- **⚠️ Supabase estourou o plano grátis:** *Realtime Messages* 2,33 mi de 2 mi (117%) no ciclo 13/11–13/12. **Restrição a partir de 16/12/2026** se continuar acima. Já cortado na v20261123b (posição a cada ~0,5 s, parado a cada 15 s, nada com aba escondida; aluguel sem gravação à toa). **Solução definitiva = mover o tempo real para o Cloudflare (seção 6).**
- **Cloudflare:** o dono **ativou (ou está ativando) o plano Workers Paid (US$ 5/mês)** para usar Durable Objects.
- **Play Store:** conta de desenvolvedor criada, **aguardando aprovação do Google** (não deixa criar app até aprovar). App já gerado e assinado.

## 4. Tudo que o jogo tem (resumo por área)
**Visual / tela**
- 2.5D: `isoP`/`setWorld`/`setCam`/`bbSet`/`wallSet`/`isoBox`; prédios em fatias; bar 3D; casas e lojas em "outra dimensão" (`SALAS`, `entrarSala`).
- Topo: ⭐ nível, 💰 dinheiro (curto: "R$ 300 mil", "R$ 1,25 mi"), relógio, 🏆 ranking (`#rankTop`); embaixo **🟢 N online** (`#irBtn`, abre painel "Ir para" com moradores, busca, lugares) e 🐟 peixes, fome/sede só abaixo de 50%. Minimapa à direita.
- Menu **☰ no canto direito acima do joystick** (abre para cima): Loja VIP 💎, Empregos 💼, Meu carro 🚗, Mochila 🎒, Perfil e fotos 👤, Passe 🎟️, Configurações ⚙️.
- ⚙️: volume, gráfico (Leve/Médio/Alto), **joystick esquerda/direita** (`CFG.joy`), 📊 medidor de desempenho (`CFG.perf`), 🎁 Presente do mês, 🏠 Ir para casa, 🛡️ Admin (só admin), 📄 Privacidade, 🗑️ Excluir conta, tutorial, conta.
- Tela de novidades 1 vez por pessoa (`NOVID='v20261125'`, `NOV_SLIDES`, coluna `moradores.novidades`).
- Relógio do jogo: `SPEED=1` → 1 hora do jogo = 1 minuto real (dia = 24 min).
- Desempenho: `imageSmoothingQuality='low'`, chão em blocos de 256, faróis em 320 px.

**Personagem / roupas**
- Provador (`abrirProvadorVisual`), roupas grátis/compradas (`guarda_roupa`, `_confere_roupas`), Loja de Roupas, joias (40–49), VIP (50+), **itens exclusivos 30–39** (`OPC.chapeu.exc`: gorro de Papai Noel 30, gorro brilhante 31 — não vendem).
- **Roupas VIP com formato próprio** (fim de `vipm`/`vipf`): Bomber dourada com pelo, Puffer neon, Sobretudo de veludo (até o joelho), Smoking com capa (m) / Vestido de lantejoulas (f); tênis neon, boné neon.
- **Estampas redesenhadas** (13, mesmos índices).
- **👕 Guarda-roupa** (`abrirGuarda`, `#mGuarda`): abas Roupas/Baixo/Calçados/Cabeça/Acessórios/Estampas/✨Brilho, miniaturas com o próprio boneco (`grThumb`), 3 looks salvos (localStorage), botão "🎨 Cores e cabelo" (provador). Aberto pelo cartão do próprio jogador.
- **✨ Brilho no chão** (`moradores.rastro`: 'ouro' VIP, 'natal' do passe, 'nenhum'; função `usar_rastro`).

**Empregos**
- Pagos por tarefa (`tarefa_feita`, 2,5 s mínimo): dinheiro = salário/6 (+6%/nível acima), XP = xp/5.
- **Bônus R$ 50 a cada 10 tarefas** (`moradores.tarefas_seq`), **multa R$ 25 por erro** no minijogo (`erro_tarefa`, pescador isento, nunca negativo).
- Pontos do passe por emprego conforme o tempo (`_pontos_tarefa` / `PONTOS_JOB`): garçom/frentista/barbeiro/vendedor/pescador 2; repositor/mecânico/prefeito 3; caixa/delegado 4; gerente 6; lixeiro 7; enfermeiro/padeiro 8; médico 9; operário 12; servidor público 15.
- **Polícia:** patrulha sem limite, R$ 50 + 20 XP a cada 90 s (`ronda_policia`), viatura com giroflex/sirene.
- Padeiro, operário (gelo) e lixeiro entregam/coletam **pela cidade inteira** (`pontosCidade`).

**Casas / condomínio**
- Casas da cidade (até 1 de cada tipo), mansão 2 andares, móveis (Decorar), geladeira. Condomínio Vila Tonhão (64 aptos, ids 1101–1444, compra ou aluguel semanal, 3 dias de atraso = despejo). Imobiliária com corretor.

**Carros**
- 32 ângulos, rodas girando, cores, LEDs/lanternas/neblina copiados dos desenhos do dono (`FAROL_FORMA`, `FAROL_POS`, `farolQuadro`). **Sons reais de motor** (`sons/*.mp3`, `GRAV`/`GRAV_RPM`).

**Sinuca**
- 15 bolas (1–7 lisas, 8 preta, 9–15 listradas). Sozinho: 10 tacadas, 3 XP por bola (`sinuca(p_bolas<=15)`). Dupla: regra 8-ball (primeira bola define grupos, 8 antes da hora perde), vencedor 30 XP / perdedor 10 XP (`sinuca_dupla`), 90 s entre partidas com XP.

**Monetização**
- Loja 💎 (Pix): VIP 30 dias (R$ 15,99), VIP 90 dias (R$ 39,90), pets, carros premium (Fusca Dourado, Caminhonete do Tonhão, Ferrarini), **Passe Premium Natal na Vila R$ 9,90** (`passe_T1`).
- **VIP:** coroa azul, Lambordini liberada, roupas/cores exclusivas, 🎁 presente do mês (`vip_mensal` até 2027-04, `presente_vip`), 🏠 ir para casa, +50% pontos no passe, brilho dourado.
- **Passe "Natal na Vila"** (T1, até 01/01/2027): 20 níveis × **300 pontos**; grátis = dinheiro + gorro normal (nível 5) + estampas; premium = gorro brilhante (1), roupas, brilho de Natal (12), **R$ 26 mil** (níveis 4, 8, 10, 15, 19) e **carro exclusivo no nível 20** (`{"carro":"natal"}`, travado até `passe_temporadas.carro_pronto=true` e existir `CARS_PREMIUM.natal` no cliente). Quem compra o premium depois recebe tudo que já alcançou. Tela estilo Fortnite/Clash (`abrirPasse`, `thumbPremio`).
- **No app da Play Store a loja Pix fica escondida** (`NO_APP`, detecta `?app=1`): regra do Google (jogos só podem usar o faturamento do Google). Compras pelo site valem no app.

**Mochila nova** (`abrirMochilaNova`): abas Itens (grade 20 espaços, Usar), Roupas (guarda-roupa), Carros (dirigir), Pets.

**Segurança**
- Nenhuma tabela aceita escrita direta (RLS); tudo por funções `security definer` que conferem `_eu()`. Pix conferido no Mercado Pago. Funções internas fechadas. Bloquear jogador (🔇, `BLOQ` no aparelho) e denunciar.
- Risco conhecido: script chamando `tarefa_feita` a cada 2,5 s. **O dono NÃO quer limite de ganho por hora.**

## 5. Banco (principais funções e tabelas)
Funções que o jogo chama: `criar_morador`, `comecar_trabalho`, `tarefa_feita`, `terminar_trabalho`, `largar_trabalho`, `erro_tarefa`, `ronda_policia`, `pulso`, `comprar`, `guardar_item`, `usar_item`, `comprar_carro`, `vender_carro_loja`, `propor_venda`, `responder_proposta`, `cor_carro`, `usar_carro`, `abastecer`, `salvar_gasolina`, `comprar_casa`, `comprar_apto`, `alugar_apto`, `sair_apto`, `cobrar_aluguel`, `comprar_movel`/`mexer_movel`/`guardar_movel`/`colocar_movel`, `geladeira`, `porta_casa`, `comprar_roupa`, `usar_pet`, `usar_rastro`, `sinuca`, `sinuca_dupla`, `meu_passe`, `resgatar_passe`, `presente_vip`, `vip_info`, `enviar_msg`, `postar`, `apagar_post`, `seguir`, `definir_foto`, `atualizar_perfil`, `denunciar`, `assumir_prefeitura`, `deixar_prefeitura`, `missao_passo`, `comer_fruta`, `vender_peixes`, `visto_novidades`, `excluir_conta`, `admin_acao`.
Internas (não chamáveis): `_eu`, `_estado`, `_entregar` (só a Edge Function pix), `_dar_premio`, `_passe_pontos`, `_pontos_tarefa`, `_temporada_atual`, `_vagar_apto`, `_confere_roupas`, `_gastar_fome`, `_adm`.
Tabelas novas da etapa 28: `passe_temporadas`, `passe_premios`, `passe_jogador`, `vip_mensal`, `vip_presentes`; colunas `moradores.rastro`, `moradores.tarefas_seq`, `passe_temporadas.carro_pronto`.

## 6. PRÓXIMO PASSO 1 — Tempo real no Cloudflare (economizar o Supabase)
**Por quê:** Supabase Pro custa US$ 25/mês (5 mi mensagens, cada entrega conta). Cloudflare Workers Paid custa US$ 5/mês e as mensagens que o servidor manda para os jogadores **são grátis** (só conta o que o jogador envia, dividido por 20).
**Já feito:** servidor escrito em `tempo-real/` (`wrangler.toml` + `src/index.js`): Worker `vila-tempo-real` com Durable Object `Sala` (uma por sala 1–60), WebSocket com hibernação, confere o login no Supabase (`/auth/v1/user` com o token), repassa `pos`, `ev` e `chat`, presença (`oi`/`entrou`/`saiu`), sala cheia com 50, rota `?contar=1`.
**Falta fazer:**
1. O dono colocar no ar **pelo GitHub** (ele não consegue copiar código pelo celular e **recusou dar token da API**): Cloudflare → Workers & Pages → Create → **Import a repository** → GitHub `vila-do-tonhao`, branch `ccr-e8b9720b-5amd2g`, **Root directory `tempo-real`**, deploy command `npx wrangler deploy`. Ele manda o endereço `vila-tempo-real.XXX.workers.dev`.
2. **Ligar o jogo ao servidor** (no `index.html`): criar `CONF.realtimeUrl`; em `conectar()` usar WebSocket `wss://…/sala/N?token=<access_token>&k=<anon key>` em vez de `sb.channel`; trocar `canal.send({type:'broadcast',event,payload})` por `ws.send(JSON.stringify({t:event,p:payload}))`; `presenceState()` vira a lista de ids recebida em `oi`/`entrou`/`saiu`; depois de `api.msg()` mandar `{t:'chat',r:row}`; receber `chat` → `onChat`. Manter fallback para o Supabase se o WebSocket falhar. Os avisos de `casas`/`vagas` (postgres_changes) podem continuar no Supabase (são poucos) ou virar `ev`. Espiar a sala sem login: conectar sem token (só recebe).
3. Testar com 2 abas, subir `site.zip`, acompanhar o Usage do Supabase.

## 7. PRÓXIMO PASSO 2 — Lançar na Play Store
**Já feito:** app TWA em `app-android/` (Bubblewrap; pacote **`br.com.viladotonhao.app`**, versão 1.0.0, targetSdk 35, abre `/?app=1` em tela cheia). `.aab` e `.apk` assinados (o dono tem). Chave: `cidade-do-tonhao.keystore`, alias `tonhao`, SHA-256 **C0:AF:D0:CF:99:83:65:6D:15:A9:B2:9C:81:3D:69:5F:BA:A6:AE:D4:E3:05:C3:EA:2D:48:C9:A5:1E:68:96:AE** (já no `/.well-known/assetlinks.json`, que abre no site ✔). Política de privacidade e exclusão de conta no ar. Imagens da loja prontas (ícone 512, destaque 1024×500, 4 prints). Passo a passo completo em `GUIA-PLAY-STORE.md`.
**Falta fazer (em ordem):**
1. Esperar o Google aprovar a conta (e-mail para obiellsilva@gmail.com).
2. Criar o app no Play Console (nome Cidade do Tonhão, Português BR, Jogo, Gratuito) e preencher o painel conforme o guia (privacidade, acesso com conta de teste para o revisor, sem anúncios, classificação IARC, público 13+, segurança dos dados, link de exclusão de conta).
3. Status de comerciante (UE): **"Não sou comerciante"**; países: Brasil (e Portugal se quiser).
4. **Teste fechado obrigatório:** subir o `.aab`, **12 testadores** (Gmail) com o app instalado por **14 dias seguidos**. Sugestão: aviso no jogo chamando jogadores.
5. Depois de enviar o `.aab`: pegar o **SHA-256 da chave de assinatura do Google** (Configuração → Integridade do app) e **acrescentar** no `assetlinks.json` (manter o atual também) → subir site.
6. Após 14 dias: solicitar acesso à produção e enviar para revisão.
**Recompilar o app** (se precisar mudar versão): Android SDK em `/opt/android-sdk` (instalar de novo no ambiente novo), `cd app-android && ./gradlew bundleRelease`, assinar com `jarsigner` usando a keystore. Maven Central pode dar 429: usar o espelho `https://maven-central.storage-download.googleapis.com/maven2/`. Aumentar `versionCode` a cada envio.

## 8. Pendências / ideias anotadas
- **Carro exclusivo do passe** (nível 20 premium): o dono vai mandar o modelo. Ao chegar: sprite com id `natal`, `CARS_PREMIUM.natal`, e `update passe_temporadas set carro_pronto = true where id = 'T1';`.
- Equilibrar **dinheiro por emprego** (hoje garçom ~R$ 64/min e servidor público ~R$ 12/min) — o dono ainda não decidiu.
- **Missões diárias** (pontos extras do passe 1×/dia) — sugerido.
- Desempenho: luz da noite mais leve e prédios/muros pré-desenhados (o dono reclamou de travadas; medir com o 📊).
- Kombi e Fusca Dourado: modelos 3D novos (o dono mandaria).
- Interiores de todas as lojas em "outra dimensão" (menos o bar).
- Curva de XP para a Play Store (níveis 1–9 ×0,7; 10–19 ×0,91; 20–34 ×1,18; 35–50 ×1,54 do passo 50×n), convertendo o XP de cada jogador.
- Fechar compra da Lambordini pelo Pix (produto `carro_neon` ainda existe; hoje ela vem com o VIP).
- Próxima temporada do passe (T2): inserir em `passe_temporadas`/`passe_premios`, produto `passe_T2`, atualizar `PASSE_T1`/textos no cliente e o item exclusivo novo.

## 9. Como testar (ambiente do assistente)
- **Arquivo de teste offline:** cópia do `index.html` com `const ONLINE=false&&!!(` e, antes de `window.__dbg={`, um bloco que: libera todos os carros (`Object.assign(CARS,{sw4,viatura,duster,frontier,caminhao,lixo},CARS_PREMIUM)`), fecha o tutorial sozinho, cria o botão "🧪 Carros", entra direto com um personagem "Teste" (`abrirProvador()` + `$('enter').click()`) e põe nível 30, R$ 300 mil, VIP 1 ano e todos os carros tanto em `aplicarEstado` quanto em `L.me` (banco local, `lsave()`). Publicar como Artifact privado com a pasta `sons/`.
- **Banco de teste:** PostgreSQL local com esquemas falsos `auth` (users, `auth.uid()` lendo `request.jwt.claim.sub`) e `storage`; rodar `banco.sql` (só dá erro na `supabase_realtime`, normal).
- **Prints:** Playwright já instalado (`require('playwright')`), viewport de celular 400×820.
- O dono pede para conferir em **vários ângulos** (frente, diagonal, perfil, costas) quando mexer em personagem/carro e cobra muito capricho.

## 10. Regras do dono (importante)
- Português simples, curto, passo a passo. Ele **só tem celular**.
- Confirmações dentro do jogo (`confirmar(...)`), nunca alert/confirm do navegador.
- VIP e loja = visual e conforto, **sem vantagem no ranking**. Não vender dinheiro do jogo/XP.
- Sempre mandar `site.zip` **e** `index.html` solto; trocar `VERSAO_JOGO` a cada versão.
- SQL grande: dividir em partes de ~6,5 mil letras (ele achou 9 partes demais; 4 está bom).
- Mandar foto + link de teste antes de pedir para subir.
- Não usar conteúdo com direitos autorais (sons de GTA/FiveM, marcas reais).
- Ele **recusou** dar o token da API do Cloudflare ao assistente: usar o caminho pelo GitHub.
- **Não colocar limite de ganho por hora** nas tarefas.
