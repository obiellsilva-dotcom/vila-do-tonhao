# Vila do Tonhão — guia completo para o próximo chat (atualizado em 22/11/2026)

> **Para o assistente:** o dono **não é programador**, usa **só o celular** e tem **pouco limite de uso**. Responda em **português do Brasil, simples, curto e passo a passo**. Edite pontos específicos, não reescreva arquivos inteiros. **Teste antes de entregar** (ele cobra muito isso). Leia a seção 10 (regras) antes de qualquer coisa.

---

## 0. COMO TRABALHAR NESTE PROJETO (o fluxo que funciona)

1. **Ramo de trabalho:** `claude/new-session-ylq39m` (tem TUDO: jogo, banco, app, servidor, ferramentas). Se o ambiente pedir outro nome de ramo, crie a partir dele: `git fetch origin claude/new-session-ylq39m && git checkout -b <seu-ramo> FETCH_HEAD`.
2. **Ramo `main` = o que está NO AR.** Só tem `site/` (o site) e `tempo-real/` (servidor ao vivo). O Cloudflare publica sozinho quando o `main` muda. **Nunca mexa no `main` sem o dono dizer "pode" ou "vamos subir"** naquela hora.
3. **Subir o jogo (automático):** `ferramentas/subir-site.sh` → copia `index.html`, páginas e ícones para `site/public/` no `main`, dá push, espera e confirma "NO AR". Antes, troque `VERSAO_JOGO` no `index.html` (formato `v2026MMDDx`) — o jogo avisa os jogadores que tem versão nova.
4. **Subir o servidor ao vivo:** `ferramentas/subir-servidor.sh` (copia `tempo-real/` para o `main`).
5. **SQL (banco):** o assistente **não tem acesso** ao Supabase. Escreva o SQL, teste num PostgreSQL local (seção 9), salve em `banco.sql` (completo) e numa parte curta `entrega/sql-parteN.sql`, e **mande o arquivo** para o dono colar no SQL Editor do Supabase.
6. **App da Play Store:** só precisa de versão nova se mudar **ícone, nome, pagamento ou algo do Android**. Todo o resto (jogo, loja, correções) vai pelo site e chega sozinho. Para gerar: `ferramentas/instalar-android-sdk.sh` e `ferramentas/gerar-app.sh` (roda os testes de abertura em 12 versões do Android antes). **Precisa da chave** (seção 7).
7. **Link de teste para o dono:** `python3 ferramentas/teste-offline.py <pasta>` cria uma cópia que roda sem banco; publique como **Artifact privado** (com a pasta `sons/`) e mande o link. Mande **foto** também.

---

## 1. O que é o jogo
**Vila do Tonhão: Cidade Online** — jogo online de navegador e app Android, um único `index.html` (canvas 2D, visão isométrica 2.5D) de uma cidadezinha brasileira com o **Bar do Tonhão**. Personagens customizáveis, 18 empregos com minijogos, fome/sede, XP e nível (até 50), casas e apartamentos, carros 3D (fotos de 32 ângulos), chat por salas, sinuca, VIP, loja (Pix no site / Google Play no app), pets, perfil social, passe de temporada, prefeito, títulos, celular no jogo, moderação.

## 2. Onde está cada coisa
| Peça | Onde |
|---|---|
| **Site** | https://viladotonhao.com.br — Cloudflare Worker `viladotonhao`, ligado ao GitHub (ramo `main`, pasta `site`, arquivos em `site/public/`). Publica sozinho. |
| **Servidor ao vivo** | Worker `vila-tempo-real` (`https://vila-tempo-real.obiellsilva.workers.dev`), pasta `tempo-real/` no `main`, publica sozinho. Salas (60×50), posições, chat, `/salas` (contagem), `/glob` (avisos de casa/vaga vindos do banco), **fotos no R2** (bucket `vila-fotos`: `POST /foto`, `GET /f/...`, `DELETE /foto`). |
| **Banco** | Supabase, projeto `fyviodritpungccrohvd`, plano **Free**. `banco.sql` = banco completo (pode rodar de novo). Etapas até **44** escritas. Chave pública (anon) está no `index.html` (`CONF.supabaseAnonKey`). |
| **Funções do Supabase** | `pix` (Mercado Pago, arquivo `pix-funcao.ts`) e **`swift-api`** (= compras do Google Play, arquivo `play-funcao.ts`; o Supabase deu esse nome, o jogo chama `swift-api`). Segredos: `MP_ACCESS_TOKEN`, `GOOGLE_SA_JSON` (conta de serviço `vila-play@vila-do-tonhao.iam.gserviceaccount.com`). |
| **App Android** | `app-android/` — **app nativo** (WebView + Google Play Billing 8.0), pacote `br.com.viladotonhao.app`. Abre `https://viladotonhao.com.br/?app=1` dentro do app (sem navegador, sem barra). Ponte JS `window.AndroidPlay` (detalhes, comprar, consumir, pendentes, versao). Última versão: **2.0.4, código 22** (ícone novo da casa com piscina) — gerada, **o dono decide quando enviar**. No ar no teste fechado: 2.0.3 (código 21). |
| **Play Console** | Conta pessoal "JogosDinamicos" (ID 8326030666609860618), app ID 4972213323568152748. Teste fechado "Alpha", Brasil. 15 produtos ativos (vip30, vip90, passe_t1, din10/20/50/100, carro_fusca_ouro, carro_kombi_tonhao, carro_gto, pet_*). Teste de licença: lista "Licença - Dono". Conta de teste do revisor: `obiellsilva+revisor@gmail.com` (senha está no Play Console → Acesso ao app; VIP até 11/2027). |
| **Repositório** | GitHub `obiellsilva-dotcom/vila-do-tonhao` |
| **Pagamento site** | Mercado Pago (Pix), função `pix`. Preço vem da tabela `produtos`. |

## 3. Situação AGORA (22/11/2026)
- **Site no ar:** `v20261127d` (24/11). **Jogo e site estão em dia**, nada pendente para subir.
- **Banco:** etapas até a **44 confirmadas**. **Etapa 45** (comércios) rodada pelo dono e confirmada no ar (24/11).
- **Play Store:** teste fechado aprovado e funcionando, compras testadas e funcionando. **Falta juntar 12 testadores por 14 dias seguidos** → depois pedir acesso à produção. Testador entra assim: manda Gmail → dono põe na lista "Testadores da Vila" → manda o link `https://play.google.com/apps/testing/br.com.viladotonhao.app` + código **`PIONEIRO-VILA`** (título 🧪 Pioneiro, vale até 28/02/2027).
- **Supabase:** estourou "Realtime Messages" entre 14 e 18/11 (3,4 mi de 2 mi). Desde 19/11 ~zero (tempo real foi para o Cloudflare). Aviso: restrição em **16/12** se continuar acima. Recomendado ao dono: abrir chamado no suporte do Supabase ou assinar Pro por 1 mês antes de 16/12. **Perguntar o que ele fez.**
- **Celular do dono:** o app antigo mostrou barra de endereço no aparelho dele (problema do aparelho). Com o app nativo (2.0+) isso acabou.

## 4. Tudo que o jogo tem (resumo)
**Visual:** 2.5D isométrico; casas/lojas em "outra dimensão" (`SALAS`, `entrarSala`); dia = 48 min reais; noite escura com luzes (postes, faróis, giroflex, móveis de luz dentro de casa).
**Painéis (celular primeiro):** bottom sheet no celular, centro no PC. Loja 💎 com cartões e fotos dos carros (abas VIP, Dinheiro, Carros, Pets, Roupas); perfil estilo cartão (`verPerfil`) com títulos, emblemas, garagem e fotos; empregos em cartões; Imobiliária em lista (`imobLista`); Decorar com abas fixas.
**Casas:** compra/aluguel, condomínio com **apartamentos sem limite** (`_garante_aptos` cria blocos E, F, G… nos mesmos prédios; cliente `aptoVirtual`), móveis (100+), **cor de parede/piso/janela** (`estilo_casa`), luzes dos móveis à noite (`LUZ_MOV`), Luz de teto, móveis encostam na parede construída (`encosto`).
**Economia (etapa 39):** casas 30k/45k/75k/mansão 350k; kitnet 15k (aluguel 1.500/sem), 2 quartos 25k (2.500/sem). Pacotes de dinheiro 10k R$ 9,90 / 20k R$ 18,90 / 50k R$ 44,90 / 100k R$ 84,90, limite R$ 100 mil/semana. Hillux R$ 15,90.
**Títulos (etapa 41):** `TITULOS`/`RAR` no cliente; `meus_titulos`, `usar_titulo`, `resgatar_codigo`; tabela `codigos`. Raridades com cor/efeito (comum, raro, épico brilha, lendário dourado animado, único arco-íris, apoiador).
**Polícia:** viatura com giroflex/sirene; **uniforme novo** (camisa e calça cinza, colete preto "POLÍCIA", cinto, coturno, boina — funções `colete` e `boina`); **viatura fica estacionada** quando o policial desce (com giroflex se estava ligado; eventos `vtr`/`vtrOff`; `trabalho.vp`), anda sozinho até ela para voltar. Mesmo para a Duster do prefeito.
**Dentro de veículo:** nome, foto, coroa VIP, troféus, ADM e título **somem**; voltam ao descer (decidido a cada quadro com `carOf(p)`, sem estado).
**Admin (🛡️):** dinheiro, VIP, **definir nível** (etapa 44), pet, carro, casa, silenciar, banir, expulsar, denúncias, ideias (inclui pedidos de testador "TESTADOR PLAY STORE: email"), aviso geral.
**Convite de testadores:** aparece 1 vez para quem joga pelo site + ⚙️ → 🧪 Testar o app (só no site).
**Diagnóstico da loja no app:** ⚙️ → 🔧 Diagnóstico (mostra `PLAY_DIAG`).

## 4b. Novidades da v20261127b (ainda NÃO no ar em 24/11)
- **Prédios desenhados à mão** (`N3D`, `n3Desenha`, `n3Kit`): igreja (2 torres, frontão barroco), prefeitura (colunas, relógio, bandeiras), delegacia (torre azul com brasão, marquise, grade), hospital (heliponto, pronto-socorro), banco ("BANCO DA VILA", caixa 24h). Arte pintada 1x por dia/noite e desenhada em fatias com profundidade certa. Luzes de janela à noite (`a.luzes`).
- **Comércios dos jogadores** (etapa 45): Lanchonete (x16-23,y41-46) e Loja de Roupas da Vila (`butique`, x25-31,y41-46), no quarteirão entre a praça e a avenida. Tabelas `comercios`, `comercio_catalogo`, `comercio_itens`; funções `comercios`, `comprar_comercio`, `com_repor`, `com_preco`, `com_recolher`, `com_nome`, `com_comprar`; `_com_atualiza` conta as vendas dos bonecos pelo tempo (máx. 72h) e a conta de luz/água semanal (2 atrasos = perde o ponto). Um comércio por pessoa. Cliente: `abrirComercio`, `COM_CAT`, `comLocal` (modo offline).
- **Roupas novas (24-29, `ROUPAS_COL`)**: Jaqueta universitária, Camisa anos 70, Kimono florido, Poncho gaúcho, Camisa com suspensório, Jaqueta bomber. Só vendidas na loja dos jogadores (2 modelos por semana no fornecedor, `_colecao`). A loja oficial recusa 24-29. Comprar dá `roupa_m` e `roupa_f`. **Roupas normais novas têm que ficar abaixo do índice 24.**

- **OUTRA DIMENSÃO (v20261127d)**: TODAS as salas (casa, mansão, kit, ap2, imob, show e prédios públicos) ficam numa faixa extra da grade DEPOIS do fim do mundo (`XR=48` linhas, y 100 a 147; `inWorld` vai até lá, `G2` maior, `WY1E`). Nada é desenhado nem visto de fora. Antes as salas ficavam na floresta da borda e apareciam como manchas, e as salas novas chegaram a cobrir o pomar: corrigido. Nunca colocar sala dentro do mapa/margem de novo.
- **Interiores dos prédios públicos**: delegacia (térreo recepção + 2º andar carceragem com 3 celas), hospital (térreo recepção/pronto-socorro + 2º andar internação com 6 leitos), prefeitura (térreo atendimento + 2º andar gabinete), banco e igreja (12x12). Escada igual à da mansão (`esc`, `cima`). Código: `PUB_SALA`, `SALAS.p_*`, `PUBB`, `pubDef`, `pubItens`, `pubBloq`, `pubOpcoes`. Na porta: "🚪 Entrar"; emprego no balcão (abre `abrirLugar`); ao começar o trabalho sai sozinho da sala.
- **Aviso de novidades** (`NOVID='v20261128'`, `NOV_SLIDES` com 8 telas) FEITO e no ar em v20261128a: aparece 1 vez por jogador (localStorage + `visto_novidades`).
- **Etapa 4 (prédios do condomínio)** FEITA: `N3D.bloco` (portaria com marquise, sacadas de vidro, ar-condicionado, faixa da escada, casa de máquinas, caixa d'água). **Emprego Vendedor de carros** consertado (a concessionária abria direto a vitrine; agora mostra vitrine + emprego).
- **LOTES (v20261127g)**: `LOTES_DEF` define 28 lotes ([x,y,largura,fundo,nº da casa]); as outras casas ficam desligadas (`HOUSE_OFF`). As 17 casas com dono continuam com o mesmo número/dono, só mudaram de lugar. Cada lote: muro (tiles BLD), portãozinho (na coluna da porta) e portão de carro (2 tiles) que abrem sozinhos (`loteItens`, `lotePortao`), entrada de carro + garagem coberta (`LOTE_CAR`, vaga `g`+nº dentro do lote), caminho até a porta, 3 canteiros de horta (mansão 4 + piscina). Quintal = tiles `G.CASA` em `loteTile` (só entra quem `podeEntrar`); `pathTo` não deixa atravessar lote alheio. Rua de terra na linha 39 (TRAIL). **Bairro Nobre**: rua nova no alto (y -10/-9, x 62-123) ligada pela x 82-83, 4 mansões; mais 2 mansões no quarteirão leste.
- **Plano combinado com o dono (uma etapa por vez, ele aprova cada uma):** 1 interiores com emprego (FEITO e NO AR v20261127d) · 2 interiores das lojas (FEITO v20261127e, aguardando aprovação: loja de roupas oficial virou prédio novo `N3D.roupas` + sala `p_roupas` com vendedora, araras, manequins e provadores; lanchonete `p_lanchonete` com chapa, geladeira, mesas e cardápio com os preços do dono; loja da vila `p_butique` com manequins vestindo a coleção. A loja oficial NÃO é mais andável por dentro na cidade.) · 3 casas (FEITO v20261127f, aguardando aprovação): 9 modelos (`n3Casa`, `casaModelo`, `CASA_MOD`: pequena térrea/colonial/chalé, média sobrado/moderna/garagem, mansão clássica/moderna com piscina/casarão) com quintal, muro e portão; cache LRU `N3MAX=40`. **Hortinha** (etapa 46, `entrega/sql-parte9.sql`, PRECISA RODAR antes de subir): tabelas `hortas`, `horta_plantas`; funções `hortas`, `plantar`, `colher`; 3 canteiros (mansão 4); colheita vai para a mochila (itens `h_*` na tabela `loja`, local 'horta'). Cliente: `HORTA_PL`, `abrirHorta`, botão '🌱 Minha horta' na frente da casa do dono. · 4 prédios de apartamento de verdade.

## 5. Banco — etapas recentes
36 Luz de teto · 37 estilo da casa · 38 avisos de casa/vaga pelo Cloudflare (`pg_net` → `/glob`) · 39 economia + pacotes de dinheiro + limite semanal · 40 apartamentos sem limite · 41 títulos/conquistas · 42 fotos no R2 (aceita URLs do Worker) · 43 índice único para compras do Google Play (`pedidos_gp_unico`) · 44 admin define nível · 45 comércios dos jogadores + roupas 24-29.
Segurança: nenhuma tabela aceita escrita direta (RLS); tudo por funções `security definer` que conferem `_eu()`. Compras conferidas no Mercado Pago / Google antes de entregar.

## 6. Correções importantes já feitas (não desfazer)
- `_estado` do banco **não manda `titulo`** → `aplicarEstado` só mexe no título se vier no objeto.
- `aplicarEstado` **não troca o carro** que está sendo dirigido; `pegarCarro` chama `api.usarCarro`.
- App: tela cheia só **depois** de `setContentView` (antes derrubava o app ao abrir).
- Teste offline do jogo: setinha da missão aparece no meio das fotos/vídeos — para vídeo, trocar `const a=msAlvo();if(a&&a.seta)` por `const a=null;...` na cópia.

## 7. Chave do app (SEGREDO)
`vila-do-tonhao.keystore` + senha (`senha-da-chave.txt`), alias `tonhao`. SHA-256 upload: `88:DA:40:44:...:1B:5C`. Chave do Google (Play): `7A:EC:8A:13:...:EE:39`. Ambas + a antiga estão em `.well-known/assetlinks.json`.
O dono guarda a chave. **Só peça para ele anexar a chave quando for gerar uma versão nova do app**, e **nunca** coloque a chave no GitHub nem em lugar público.

## 8. Próximos passos / ideias
1. Juntar 12+ testadores por 14 dias → Play Console → **Produção → Solicitar acesso** → revisão.
2. Enviar o app 2.0.4 (ícone novo) quando juntar outra mudança de app.
3. Resolver o aviso do Supabase antes de 16/12.
4. ~~Último uso de tempo real do Supabase~~ FEITO (v20261127a): a tela de entrada já usava o Cloudflare; foi removida a volta automática para o Supabase quando o Cloudflare falha — agora o jogo tenta de novo no Cloudflare (3s, 6s, 9s… até 30s). O código do Supabase só roda com `CONF.semCloudflare`.
5. Ideias anotadas: missões diárias; equilíbrio de salário por emprego; interiores de todas as lojas; título de vitórias na sinuca (precisa contador); próxima temporada do passe (T2).

## 9. Como testar (ambiente do assistente)
- **Jogo offline:** `python3 ferramentas/teste-offline.py /tmp/x` → abrir com Playwright (`require('playwright')`, viewport 400×820 celular) ou publicar como Artifact. `window.__t` tem atalhos (loja, perfil, polícia, carros, casas…).
- **Banco local:** PostgreSQL 16 (`/usr/lib/postgresql/16/bin`), criar esquemas falsos `auth` (tabela `users`, função `auth.uid()` lendo `request.jwt.claim.sub`), `storage`, `net.http_post` falso; rodar `banco.sql` (erros de `supabase_realtime` e `storage.foldername` são normais).
- **App:** `app-android/app/src/test` tem testes Robolectric que abrem o app no Android 7.0 a 15 (`./gradlew testReleaseUnitTest`). `gerar-app.sh` já roda.
- **Vídeo 60 fps:** técnica do relógio controlado (substituir `performance.now`/`requestAnimationFrame`, avançar 1/60 s e capturar o canvas quadro a quadro). Ver histórico em `CONTEXTO.md`.

## 10. Regras do dono (IMPORTANTE)
- Português simples, curto, passo a passo. Ele **só tem celular**.
- **Testar antes de entregar** — app no simulador (12 versões do Android), jogo no Playwright, SQL no PostgreSQL local. Ele ficou muito bravo quando um app foi entregue sem teste e fechava ao abrir.
- **Só publicar (site/servidor) quando ele disser "vamos subir"/"pode".** Mandar foto + link de teste antes.
- **Não mexer no `main` sem "pode".**
- Confirmações dentro do jogo (`confirmar(...)`), nunca alert/confirm do navegador.
- VIP e loja = visual e conforto, sem vantagem no ranking. Vender dinheiro do jogo **agora é permitido** (com limite semanal).
- **Não colocar limite de ganho por hora** nas tarefas.
- SQL grande: partes de ~6,5 mil letras.
- Nomes de carros parecidos com os reais (Fuska, Fiestta, Opalla, Amarock, Hillux, Porshe GT, Ferrarini, Lambordini…). Músicas só brasileiras. Nada com direitos autorais ou marcas reais.
- Ele recusou dar token da API do Cloudflare: o caminho é pelo GitHub (`main`).
- Nunca pedir/compartilhar a chave do app fora do momento de gerar app.
