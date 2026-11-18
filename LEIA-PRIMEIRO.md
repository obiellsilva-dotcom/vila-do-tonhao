# Cidade do Tonhão — passagem para um chat novo (atualizado em 18/11/2026, fim da sessão)

> **Cole este arquivo no começo do chat novo** e anexe o `pacote-novo-chat.zip` (ou, se não der, os arquivos soltos listados na seção 2).
> Pedido ao assistente: o dono **não é programador**, usa **só o celular** e tem **pouco limite de uso**. Responda em **português do Brasil, simples, passo a passo e curto**. Edite pontos específicos, não reescreva arquivos inteiros. Antes de mandar `site.zip`, mande **foto + link de teste** para ele aprovar. Pesquise na internet quando tiver dúvida (ele pede).

---


## 0. ÚLTIMA SESSÃO (18/11/2026) — versão `v20261124e`, ramo `ccr-fe2fa98f-j3vukg`
Tudo commitado. O dono recebeu o `site.zip` v20261124e (confirmar se subiu). SQL: **todas as etapas até a 29 rodadas** (29 = `carro_pronto=true` do passe T1).
- **Concessionária:** prédio fechado (vidro escuro, telhado, porta dupla, marquise) desenhado em `concIso`/`concFachada`; pátio de asfalto; carros do pátio em `CONC.fora`. Casa 59 removida (sem dono, conferido).
- **Showroom em outra dimensão:** `SALAS.show` (x-19..-7, y80..86), objeto `SHOW`, carros em `CONC.dentro` (coordenadas da sala), `showItens` (discos, carros, letreiro, vendedor), botões "🚗 Entrar no showroom" e "🚗 Ver e comprar carros".
- **Tour pela cidade** (`tourCidade`, 11 paradas) testado: funciona e devolve a câmera.
- **Pix do passe corrigido:** `comprarPix` agora abre `#mLoja` para mostrar o QR (antes ficava escondido).
- **Carro do Passe = "Furacão GT" (id `natal`)**: modelo "Volkswagen Golf GTI 2021" de ItsDiyor (Sketchfab, **CC BY 4.0**, crédito em `privacidade.html`), sem logos/placa. `SPR_NATAL`/`SPR_NATAL_M` (máscara de pintura), `RODA_IMG.natal` (4 quadros), `FAROL_IMG.natal` (camadas de luz dianteira/traseira usadas em `farolQuadro`), `spriteCor(...,fiel)` só para ele (vidros/faróis não escurecem). Renderizador em `extras/render-carro.html` + `extras/render-carro-gerar.js` (three.js 0.160 + Playwright, servidor local). Os modelos do autor "Ddiaz Design" são **CC-BY-NC** (não usar).
- **Mapa e mapinha:** área ampliada (`MAPX0/MAPY0...`, `naSala`, `MAPA_BLOCOS`), mostram condomínio, lagoa e acampamento; nomes Imobiliária e Condomínio no mapa grande.
- **Dia do jogo = 48 min reais** (`DIA_ESC=.5`, `gmin()`; antes 24 min). Versão v20261124f.
- **Tempo real no Cloudflare (v20261124g, ainda não subido):** Worker `vila-tempo-real` no ar em `https://vila-tempo-real.obiellsilva.workers.dev` (deploy automático pelo GitHub, ramo **main**, pasta `/tempo-real`). Jogo usa `rtCanal`/`conectarRT` (WebSocket com o token do Supabase); posições, avisos, chat e presença vão pelo Cloudflare; casas/vagas continuam no Supabase (`dbCanal`). Se o Cloudflare falhar, `RT_OFF=true` e volta ao Supabase sozinho. Testado com servidor local (2 jogadores, posição, chat, saída, queda). **Depois de subir: acompanhar o Usage do Supabase (Realtime Messages) cair.**
- **📱 Celular (v20261124h, ainda não subido; SQL etapa 30 PENDENTE):** botão `#zcel` no menu, `abrirCelular`/`CEL`/`celChat`/`celAmigos`/`celBanco`/`celInvest`, aviso `celAvisos` a cada 25 s + evento `dm`/`amizade`. Banco: tabelas `amizades`, `mensagens`; colunas `invest_valor/invest_em/invest_bloq_ate/invest_ganho`; funções `pedir_amizade`, `responder_amizade`, `desfazer_amizade`, `meus_amigos`, `buscar_moradores`, `enviar_dm` (só amigos, 300 letras, guarda 200 por conversa), `conversas`, `conversa`, `nao_lidas`, `banco_info`, `investir`, `resgatar` (1%/dia sobre até R$ 100 mil, 24 h preso), internas `_sao_amigos`, `_render`, `_banco`. Testado em PostgreSQL local. Sem transferência entre jogadores (evita venda de dinheiro do jogo).
- **🛡️ Moderação (v20261124i; SQL etapa 31 PENDENTE; servidor tempo-real precisa ir para o ramo main):** `_norm`/`_grave`/`_moderar` (grave = bloqueia + silencia 10 min/1 h/24 h + denúncia automática), `silenciado_ate`, admin `silenciar`/`dessilenciar`, `admin_denuncias`/`admin_feedbacks`/`admin_resolver`/`admin_contagem`, `enviar_feedback`; denúncia com motivo e últimas mensagens (`denunciarJogador`), 🚩 na conversa do celular, ⚙️ → 💬 Ideias e problemas, painel do admin com 🚨 Denúncias e 💬 Ideias. Worker: só repassa chat que existe no banco (confere pelo REST). Tour agora só depois de COMPLETAR ou PULAR a missão (some a missão/menu durante o tour). Celular ajustado para telas pequenas.
- **🎵 Jukebox (v20261124j; SQL etapa 32 PENDENTE junto com a 31):** catálogo `MUS` (3 da Vila + 18 de Kevin MacLeod, CC BY, crédito em privacidade.html; mp3 mono 56 kbps em `musicas/`), `abrirJuke` por estilo; jukebox da casa grava em `casas.juke` (`tocar_jukebox`, só o dono), toca sincronizada para quem está dentro (`Som.casaToca/casaPara`, `JUKE_CASA`, evento `juke`).
- **🎵 Músicas (v20261124k):** catálogo = 3 da Vila + 6 sertanejo do Pixabay (`MUS`, crédito em privacidade.html); as 18 do Kevin MacLeod foram removidas a pedido (só brasileiras).
- **⚡ Desempenho (v20261124k):** corte do que está fora da tela no laço de desenho (`CULL`, itens podem ter `cb:[x0,y0,x1,y1,altura]` ou `nc:1` para nunca cortar); `quadro` faz no máximo 1 tratamento pesado por quadro (`QBUD`); pintura de carro só no ângulo visível (`spriteCor` devolve objeto `tint`, `tintQuadro`); fotos grandes abertas em segundo plano (`pronta(img)` com `img.decode()`). Medido com CPU 4x mais lenta: 6,5 → 10,7 fps, pior travada 6,4 s → 1,2 s. Ferramentas de medição em scratchpad (perf/conta/trava).
- **🛋️ Móveis novos (v20261124l, SQL etapa 33):** 50 móveis em `MOV` (bloco "móveis novos (leva 2)"), abas banho/lazer/efeito/luxo; efeitos animados por `D.fx(c,P,alpha)` (P = ponto já girado); `vip:1` = só VIP (cliente + `movel_vip` no servidor); `preco_movel` atualizado.
- **Móveis funcionais (v20261124m, SQL etapa 34):** `agua:z` (banheira, piscina, hidro) → "🏊 Entrar na água" (`noMovel(...,'agua')`, `aguaPorCima`); vitrola `juke:1` toca como jukebox (`temJuke` usa `MOV[t].juke`); `liga:1` → ligar/desligar pelo dono (`ligarMovel`, função `ligar_movel`, campo `off` no móvel).
- **Sentar e moto (v20261124o):** pose sentada em 3/4 usa as duas coxas abertas (antes só em `sv34`); no perfil a perna de trás aparece. Água com **lugares fixos** (`lugares` no MOV, estilo Habbo; cheio = aviso). Moto: `pilotoMoto` (tamanho normal PS, no banco, vista certa pelo ângulo, carenagem redesenhada por cima das pernas, `MOTO_HOP`), pintura fiel (sem peças pretas).
- **Água e moto (v20261124p):** na água o boneco afunda (hop negativo só com `aguaZ(p)`), é cortado na linha da água (clip no item do jogador), sem mancha por cima (só ondinha); lugares fixos em duplas: `lugares:[x,y,vx,vy]` (vx,vy = para onde o corpo vira, girado junto com o móvel; sv/back/dir calculados como no sofá). Moto: pose `moto` (pernas dos dois lados, joelho dobrado no perfil, braços `arms`), `MOTO_HOP=5`, `MOTO_CLIP=8`. Sentado 3/4: duas pernas lado a lado.
- Novidades: `NOVID='v20261127'` com slides Furacão GT, Concessionária nova e Passeio.
- **Próximos passos:** tempo real no Cloudflare (seção 6) e Play Store (seção 7).

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
| **Repositório** | GitHub `obiellsilva-dotcom/vila-do-tonhao`, ramo atual **`ccr-fe2fa98f-j3vukg`** (tudo commitado) |
| **Link de teste** | https://claude.ai/artifact/RFsiyLQ5LoK1cGEiWNE72V (cópia offline, dá o Furacão GT ao entrar). Antigo: C4QSmTKE8EojyVzA72WX4d (conta antiga; cópia offline com nível 30, R$ 300 mil, VIP, todos os carros, botão "🧪 Carros"). **Na conta nova crie outro**: copie o index trocando `const ONLINE=!!(` por `const ONLINE=false&&!!(` e inserindo antes de `window.__dbg={` o bloco "trapaça" (ver seção 9) |
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
- **Só gerar/mandar `site.zip`, `index.html` e SQL quando o dono disser "vamos subir".** Até lá, ir juntando as mudanças (commitar no GitHub normalmente) e, na hora, mandar tudo de uma vez com a lista do que mudou e o SQL pendente.
