# Cidade do Tonhão: contexto para continuar em outro chat

> Cole este arquivo no começo de uma conversa nova e anexe: `index.html` (versão no ar), `index-iso.html` (versão isométrica em teste), `banco.sql` e `pix-funcao.ts`.
> Pedido ao assistente: **economize meu limite de uso**. Faça só o que eu pedir, edite pontos específicos (não reescreva o arquivo inteiro), teste o mínimo e responda curto.

## O que é
Jogo online de navegador (um único `index.html`, canvas 2D) de uma cidadezinha brasileira com o Bar do Tonhão: personagens, empregos, fome, XP/nível (até 20), casas, carros, chat por salas (50 por sala, até 60 salas), sinuca, VIP, loja Pix, pets, perfil social.

## Onde cada coisa está
| Peça | Onde |
|---|---|
| Site | https://viladotonhao.com.br (Cloudflare Workers, arquivos estáticos) |
| Atualizar o site | Cloudflare → Workers & Pages → viladotonhao → **New deployment** → zip com `index.html` + pasta `musicas/` |
| Banco | Supabase (ref `fyviodritpungccrohvd`). `banco.sql` é o arquivo **completo** e pode ser rodado de novo sem perder dados |
| Pagamento | Mercado Pago (API de Orders, Pix), Edge Function `pix` (`pix-funcao.ts`). O preço vem da tabela `produtos` |
| Músicas | pasta `musicas/` (5 mp3) |

## Regras do usuário
- Ele não é programador: respostas em português do Brasil, simples e passo a passo.
- SQL: mandar o `banco.sql` completo. **Pelo celular o editor do Supabase trava com o arquivo grande**, então mandar também um arquivo pequeno só com as novidades (como `novidades.sql`).
- Confirmações sempre dentro do jogo (`confirmar(...)`), nunca alert/confirm do navegador.
- VIP e loja são só visual e conforto, sem vantagem no ranking.
- Sempre mandar o `site.zip` (index + músicas) e também o `index.html` solto (o zip às vezes não baixa no celular).
- A cada versão nova, trocar `VERSAO_JOGO` no index: o jogo avisa "🆕 Atualização" a quem está com a aba aberta.

## Feito nesta conversa (versão no ar, `index.html`)
- Sem chuva dentro do bar e das casas (`sobTeto()`). Danças mais suaves (pernas com `amp`/`flex`).
- **Perfil social**: seguidores e posts de fotos (tabelas `seguidores` e `posts`, funções `seguir`, `postar`, `apagar_post`; fotos no Storage `fotos/<id>/post-*.jpg`, comprimidas para menos de 450 KB). Botões "👤 Ver perfil e fotos" e "🙂 Foto de perfil". O painel do jogador mostra seguidores e seguindo; a fome saiu do painel. O botão antigo "Seguir" (câmera) virou "🎥 Acompanhar".
- Favicon 🍺. Gráficos 2.5D: árvores com volume, cachoeira, lago de borda natural, acampamento com fogueira e barracas.
- Embriaguez a partir da **3ª cerveja**.
- Tutorial novo com 12 passos (inclui VIP, loja, perfil e ranking).
- Loja: preços lidos do banco (`produtos`). **VIP R$ 9,90; pets R$ 5,90; Fusca Dourado R$ 10,90; Caminhonete do Tonhão R$ 12,90 (id `carro_kombi_tonhao`, desenhada com o sprite da caminhonete); Esportivo Neon R$ 15,90.**
- **Empregos pagam por tarefa** (função `tarefa_feita`, no máximo 1 a cada 2,5 s): cada tarefa paga salário/6 e xp/6, com +6% de dinheiro e +4% de XP por nível acima do mínimo do emprego. Turno livre ("✅ Encerrar turno"). Policial continua com a ronda.
- **Garçom**: escolhe o pedido no balcão e leva até a mesa (seta e anel amarelo, `comecarEntrega`, `checaEntrega`).
- **Casas mais caras**: 8.000 / 12.000 / 20.000; mansão 90.000.
- **Sinuca**: física nova (atrito, tabelas, caçapas) e mira com bola fantasma.
- Joystick menor e escondido durante as tarefas.
- **Mapa**: Centro de Empregos (Mercadinho, Padaria, Barbearia, Banco) à direita do bar, no lugar da praça antiga. Praça pequena na frente do bar (x16–31, y32–35) com árvore de Natal, pisca-pisca e 4 bancos para sentar (`PRACA_SEATS`).
- **Sentar**: cadeira de cima da mesa = de frente (`frente`), dos lados = de lado, de baixo = de costas. Pista de dança removida. Corrigido o bar "sumindo" com o zoom.
- Vídeos: `video-gancho-final.mp4` (voz ElevenLabs) e miniaturas (`miniatura-tiktok.png`, `miniatura-youtube.png`).
- SQLs avulsos: `resetar-tudo.sql` (apaga personagens e mantém os logins), `zerar-progresso.sql` (zera progresso e mantém personagens), `novidades.sql`.

## SITUAÇÃO ATUAL (atualizado)
- O site no ar usa a **versão 2.5D** (isométrica). Ela é o `index.html` deste repositório. A versão antiga, vista de cima, está em `versao-antiga-2d.html` (não é mais atualizada).
- Para publicar: zip com `index.html` + a pasta `musicas/` → Cloudflare → New deployment. A cada versão, trocar `VERSAO_JOGO` (o jogo avisa "🆕 Atualização").
- O usuário só tem **celular** e pouco limite de uso. Mande sempre o arquivo pequeno de SQL (`novidades.sql`) e respostas curtas.
- O `banco.sql` já tem tudo até a ETAPA 8 (cor dos carros) e o Policial no nível 15.

## O que tem no 2.5D (resumo)
Projeção `isoP`/`setWorld`/`setCam`/`bbSet`/`wallSet`/`isoBox`, ordenação por `k=x+y`. Prédios em fatias (`predioFatias`) com telhados de verdade; prédios e casas que estão na frente do jogador ficam transparentes. Bar todo em 3D (paredes que somem quando se entra, balcão `balcaoIso`, banquetas, banheiro). Casas com interior e móveis 3D (`movelIso`), menos casas (`HOUSE_OFF`, os números continuam os mesmos do banco). Centro de Empregos (Banco, Padaria, Barbearia e a **Feirinha**, que é o mercadinho). Mata 3D, cachoeira com paredão. Personagens maiores (`PS=.8`) e guardados prontos em cache (`PCACHE`). Qualidade gráfica automática.
- **Carros 3D** (fotos de 32 ângulos geradas com three.js; a lataria é pintada pela máscara `spriteCor`): Fusca, Sedã, Moto, Opala, Esportivo, Caminhonete do Tonhão (Hilux) e Viatura. Caminhonete normal e Neon usam os modelos antigos ajustados. O jogador escolhe a cor na compra (`carro_cores`, função `cor_carro`).
- Estacionar em qualquer lugar da rua (`estacionarAqui`, `parados`), botão "Descer do carro", **carona** (`pegarCarona`). Viatura com **giroflex e sirene**. Policial veste farda (`o.policia`).
- Sinuca com física nova e **sinuca em dupla** (eventos `sinConv`/`sinTiro`). Empregos pagos por tarefa (`tarefa_feita`). Garçom leva o pedido até a mesa.
- Entrada: tela no meio com quem está online e "Criar minha conta", provador com setas, tutorial com imagens. Menu ☰ minimizável (Empregos, Danças, Fotos, Perfil). Painel do chat ao digitar.

## Ideias para depois
Comprar móveis para a casa (precisa de tabela nova), interiores das lojas, giro da câmera em 4 posições (dá muito trabalho), opção 2D/2.5D (dá muito trabalho).

## COMBINADO PARA DEPOIS (o usuário pediu para lembrar)
1. **Interiores maiores**: casas pequenas ocuparem o terreno vazio ao lado (as casas escondidas em `HOUSE_OFF`).
2. **Loja de móveis** dentro da própria casa (botão "🛋️ Mobiliar"): escolher o móvel e tocar no chão para colocar. Do barato ao caro: cadeira de plástico, colchão, caixote → sofá, cama de casal, mesa, TV → home theater, **caixa de som**, aquário, jukebox, luzes LED. Precisa de tabela nova no banco (os móveis ficam salvos e os visitantes veem).
3. **Músicas fora do site**: guardar no Supabase Storage (bucket `musicas`, 1 GB grátis, ~200 músicas). O site.zip fica pequeno e a jukebox lista o que estiver lá. Só músicas sem direitos autorais.

## Últimas mudanças (já no ar)
Painel do admin (🛡️, só para `admin=true`, definido pelo e-mail), tag 🛡️ ADM e chat vermelho do admin, aviso para a cidade, vitrine de carros com setas, venda de carros (para a loja e entre jogadores), cargo de prefeito (🏛️ com brilho, banner ao entrar, chat dourado, vistorias), mochila, 🚗 Meu carro no menu, 10 NPCs, geladeira 3D, sem banheiro, sinuca com 4 lugares, reconexão automática da sala.

## SITUAÇÃO EM 16/11/2026 (terceira sessão) — LEIA PRIMEIRO
**Arquivos para anexar no chat novo:** `CONTEXTO.md`, `index.html`, `banco.sql`, `novidades.sql` (ou as 4 partes em `sql-celular/`) e `pix-funcao.ts`.
- `index.html` é a versão única e atual (VERSAO_JOGO v20261117g (minimapa, mapa com zoom e marcação, correção do personagem invisível)). A antiga "proposta" foi incorporada nele; NÃO use mais `extras/proposta-index.html`.
- `banco.sql` é o banco COMPLETO e atualizado (pode rodar de novo sem perder dados). Testado num PostgreSQL local.
- `novidades.sql` = atualização completa (etapas 13 a 20). Pelo celular, rodar em ordem `sql-celular/parte1.sql` … `parte4.sql`.
- **Confirmar com o usuário** se ele já rodou as 4 partes do SQL e subiu o `site.zip` (até o fim da sessão ele ainda estava testando).
- Teste sem servidor: `teste/index-teste.html` (ONLINE=false). Pelo celular o arquivo é grande demais: publicar como Artifact privado e mandar o link.

### O que entrou nesta sessão
- Estampas (13), Loja de Roupas com interior no Centro de Empregos (x52 y23, 4x5; o usuário NÃO quer maior), vitrine com boneco de frente, carrinho (paga ao sair), joias (relógios, colares, brincos; coroa 50 mil), chapéus com volume.
- Nível máximo 50 (quem estava no 20 sobe pelo XP).
- Carros 20% mais caros (moto 2.200 … esportivo 144.000), mais nítidos (função `quadro()`: processa só o ângulo visível).
- Oficina com interior (`interiorLoja(ofic,…)`): "🔧 Personalizar meu carro" com cor 1.000, rodas, vidros, pintura e som 5 mil (`carro_mods`, `personalizar_carro`). Com som, botão 🔊 ao dirigir (anéis e notas, evento `som`).
- Desempenho: luz da noite em meia resolução. **O usuário NÃO quer qualidade gráfica automática.**
- Do ramo da sessão anterior (`claude/new-session-cwzmp3`) vieram no SQL: sede, gasolina/posto, primeira missão e prefeito automático no nível 20.

- **Relógio do jogo:** `SPEED=1` → 1 hora do jogo = 1 minuto real, 1 dia = 24 minutos (antes 8).
- **Medidor de desempenho** (⚙️ → 📊 Mostrar desempenho, `CFG.perf`, `perfTick`): quadros por segundo e travadas (quadro > 0,1 s) nos últimos 10 s. O computador de teste desenha sem placa de vídeo e não serve para medir; trocar degradês da luz por imagem pronta PIOROU aqui e foi desfeito.
### Pendências
1. **Brecha:** o provador ainda deixa escolher roupas pagas de graça. Falta o passo "criação de personagem com 4 peças grátis" + `criar_morador` conferir o `guarda_roupa` (joias 40–49 também).
2. Joia: só uma por vez (relógio OU colar OU brinco). Se quiser junto, criar campo separado.
3. Kombi e Jipe só mudam a cor na oficina (não têm foto 3D). Carros nítidos de verdade exigiriam refazer as fotos em tamanho maior.
4. Próximos combinados: mapinha no canto, acessórios, poupança, loja de móveis, músicas no Storage.

## ATUALIZAÇÃO (15/11/2026, segunda sessão)
Tudo abaixo está SÓ em `extras/proposta-index.html` (ramo `ccr-e150a3c5-3uuba3` no GitHub). O `index.html` oficial NÃO foi mexido. Aplicar no oficial só quando o usuário aprovar.

### Feito e aprovado na proposta
- **Cabelos masculinos** refeitos (funções `cabeloM`, `MASC`, `cabeloM2`, `MASC2`): curto, degradê, topete, social de lado, raspado, espetado, cacheado, coque, trança (nagô), dreads, mullet + novos crop texturizado, undercut, cachos com degradê. Escondidos para homens (marcados com `'x'` em `OPC.cabelo.m`): rabo, surfista, moicano, black, comprido. Escondido = não aparece no provador/sorteio; quem já tinha vira "Curto".
- **Rosto masculino**: queixo quadrado mais fino, olhos menos abertos, sobrancelha grossa reta, boca menor.
- **Cabelos femininos** refeitos (`cabeloF`, `FEM`): comprido, coque, rabo (com rabicó rosa, preso na cabeça), cacheado e cachos longos (risquinhas onduladas), black, french bob, comprido com franja, pixie, butterfly, long bob, ondas boho, box braids, comprido com cortininha, meio preso, coque bagunçado. Escondidos para mulheres: trança, maria-chiquinha, duas tranças.
- **Calças** com modelagem própria (tabela `FITS`: largura quadril/joelho/tornozelo): baggy, wide leg, barrel, flare, pantalona, jogger, cargo larga, skinny, alfaiataria, bermuda cargo, short tactel. Shorts: perna fina e short sempre desenhado por cima.
- **Saias** novas: midi plissada, lápis, jeans longa, de tênis, minissaia jeans, envelope, tule, minissaia de couro.
- **Calçados** refeitos (frente/lado/costas) + tênis chunky, cano alto, coturno, mocassim, sandália.
- **Roupas de cima** novas: oversized, jaqueta jeans, corta-vento, puffer, blazer, suéter, camisa aberta florida, top de alcinha, ombro a ombro, cardigan, vestido tubinho. Camiseta (gola canelada), moletom (capuz, bolso, cordões), jaqueta e vestido melhorados.
- **Corpo**: mulher em formato violão (`CORPO` Path2D, cintura média), homem em V com peitoral. Quadril na cor da calça ligando ao tronco (sem emenda). Com top/cropped: umbigo, cós com botão, calça de uma cor só. Mãos com dedos (`MAO`), braços desenhados por cima do corpo de frente/costas. Sem sombra retangular atrás do corpo.

### Cuidados (o usuário cobra muito)
- Testar ampliado em 5 ângulos (frente, diagonal, perfil, outro lado, costas) e andando, antes de mandar.
- Calça/short: mesma cor e textura do quadril até o pé; nada de emenda, perna passando por cima, cós de outra cor.
- Ombro não pode passar da linha do braço; barriga não pode ficar quadrada.
- Scripts de prévia (Playwright) ficavam no scratchpad e se perdem: recriar. Truque: copiar a proposta trocando `window.__dbg={` por `window.__T={OPC,drawHead,cabelo3D,CORCAB,drawPersonReal};window.__dbg={` e chamar `__T.drawPersonReal(c,0,0,v,{cara:true}|{c34:true,dir:1}|{perfil:true,dir:1}|{lado:true,dir:-1}|{back:true})` num canvas.
- `extras/gerar-teste.py` NÃO está no repositório (pedir ao usuário para gerar o `index-teste.html`).

### Feito na terceira sessão (15/11/2026), também só na proposta
- **Estampas** (campo `estampa`, função `estampa()`): 13 opções. Aprovadas.
- **Loja de Roupas** (`lojaRoupa`, x52 y23, 4x5, no Centro de Empregos ao lado da Feirinha): interior pelo sistema das casas (araras, espelho, caixa, manequim). "👕 Ver as roupas" só aparece dentro. O usuário NÃO quer a loja maior.
- **Vitrine**: boneco parado de frente igual ao provador (`drawPerson` s 3.85). Abas: roupas, parte de baixo, calçados, cabeça, estampas, 💎 joias. Preço `precoRoupa`: 4 primeiras grátis (2 na estampa), depois R$30 subindo 15%.
- **Carrinho**: as setas experimentam e põem no carrinho (`lrCart`); ao sair (X ou Finalizar) pergunta se compra tudo (`fecharLoja`, gancho `antesFechar`).
- **Joias (luxo)**: índices 40–49 (`lux/luxm/luxf` em OPC, `LUX_PRECO` por peça). Relógio de prata 3 mil, de ouro 10 mil, cordão grosso 8 mil, corrente com pingente 6 mil (homem); brincos de pérola 4 mil, de diamante 15 mil, colar de esmeralda 20 mil, choker 7 mil (mulher). Coroa de ouro 50 mil na aba Cabeça. (O usuário NÃO quer luxo em roupa/sapato/chapéu.)
- **Chapéus com volume** (domo, costura, viseira, aba). Sobraram desenhos prontos de boné de grife, panamá e fedora (sem uso).
- SQL da proposta: `extras/novidades-proposta.sql` (visual até 60 dígitos, tabela `guarda_roupa`, `preco_roupa`, `comprar_roupa`). Ainda falta a etapa 13: `criar_morador` conferir o guarda-roupa (sem isso dá para vestir tudo pelo provador).

### Na versão do ar (index.html), ainda não publicada
- Nível máximo 50 (`NIVEL_MAX`, `nivel_de`), quem estava no 20 sobe pelo XP.
- Carros 20% mais caros (moto 2.200 … esportivo 144.000).
- Carros mais nítidos (`nitido()`: amplia 2x, realça bordas, clareia vidro/pneu).
- **Oficina com interior** (`interiorLoja(ofic,…)`; pneus, bancada, caixas de som, elevador). Dentro: "🔧 Personalizar meu carro" (`abrirMecanica`): cor 1.000, rodas (esportiva 2 mil, cromada 4 mil, dourada 8 mil, preta fosca 3 mil), vidros (fumê 800, insulfilm 1.500, espelhado 2.500), pintura (fosca 2.500, metálica 4 mil, perolada 6 mil), som 5 mil. Guardado em `carro_mods` (função `personalizar_carro`). Com som, botão 🔊 ao dirigir mostra anéis e notas para todos (evento `som`). Mods só aparecem nos modelos com foto 3D (kombi e jipe só a cor).
- SQL de tudo isso: `novidades.sql` (etapas 12, 13 e 14).

### Próximos passos (combinados)
1. **Estampas** de roupa: campo novo "Estampa" (lisa, coração, estrela, florida, xadrez, listras, bolinhas, camuflada, tie-dye, raio, caveirinha, marca inventada "Tonhão Wear"/"Vila 10"). Sem marcas reais.
2. **Banco**: o visual (`TJ…`) vai passar de 30 dígitos → no `novidades.sql` trocar a regra para até 60: `visual ~ '^(TH[0-9]{7,30}|TJ[0-9]{20,60})$'` (constraint `moradores_visual_check` e função de salvar morador).
3. **Loja de roupas nova no mapa** (prédio novo). Peças de R$ 30 a R$ 1.000+ com dinheiro do jogo. Guarda-roupa salvo no banco (tabela nova de roupas compradas, conferida pelo servidor).
4. **Criação de personagem**: só 4 opções grátis de cada peça (camisa, calça, calçado, chapéu) + estampa lisa e mais 1; o resto se compra na loja. Quem já joga mantém o que usa.
5. Depois: **mapinha** no canto de cima (toca e abre o mapa grande), oficina de carros, acessórios/coroa, poupança.
6. SQL continua acumulando em `novidades.sql`; só mandar quando ele disser "vamos subir a nova versão".

## SITUAÇÃO EM 17/11/2026 (quarta sessão) — LEIA PRIMEIRO
Versão VERSAO_JOGO v20261117g (minimapa, mapa com zoom e marcação, correção do personagem invisível). Ramo `ccr-c5db5bd8-0bdems`. Para subir: `index.html` + `musicas/` (site.zip) e rodar `novidades.sql` (pequeno) no Supabase.
Se a pessoa NÃO tiver rodado o SQL da sessão anterior, rodar o banco completo pelo celular: `sql-celular/banco-parte1..4.sql` em ordem.
### O que entrou
- Duster branca da prefeitura (vistoria). Veículos de trabalho com botão "🚚 Usar veículo do trabalho": SW4 (delegado), Frontier (mecânico), caminhão baú (padeiro e operário), caminhão de lixo (lixeiro, emprego novo nível 6). Ambulância pendente: o arquivo veio em .max (pedir .glb/.fbx/.obj/.blend).
- Amarok (id `caminhonete`, R$ 45.000, 5% menor que a Hilux) e Lamborghini (id `neon`, Pix R$ 19,90; VIP libera enquanto ativo, função `_tem_carro`).
- Rodas girando (`drawRodas`, medidas em `RODAS`). Personalização de carros REMOVIDA (só cor e som continuam).
- XP por tarefa = t.xp/20 (meta ~8 níveis/dia). Empregos em níveis maiores (prefeito 30, médico 29… ver tabela `NV`).
- Empregos no mapa (`RUA`, `proxRua`): tarefa começa indo a um ponto (seta amarela), depois minijogo. Padeiro/operário fazem entregas.
- Casas em "outra dimensão": salas em `SALAS` (casa, mansão térreo e mansão andar de cima) num canto da mata; `entrarSala/sairSala`, visibilidade por `rm` no pos. Personagem 1.8x maior dentro (`SALA_ESC`). Escada de concreto na mansão (`R.esc`).
- Móveis novos detalhados (`MOV`, `desenhaMovel`, 4 giros), painel Decorar (`abrirMobilia`, `MOB`), inventário (📦 guardar/colocar), paredes/portas (`desenhaParede`, emendam e ficam transparentes por trás), deitar/sentar/TV/geladeira. Banco: `casas.moveis`, `casas.geladeira`, funções comprar/mexer/guardar/colocar_movel e geladeira (todas recebem p_casa).
- Até 1 casa de cada tipo (barata/intermediária/mansão; coluna gerada `casas.tipo`).
- Prefeito: qualquer um no nível 30 assume se não houver prefeito (ou se sumir 3 dias); pode deixar o cargo. Aviso "prefeito entrou" no máximo 2x por dia. Top 1 de XP ganha 🏆 brilhando (some se for prefeito).
- VIP R$ 15,99: coroa azul em cima do nome (`coroaVip`), faixa azul de diamantes no chat, sem a palavra VIP. Prefeito no chat só com 🏛️.
- Tela de novidades (`mostrarNovidades`, `NOVID`) aparece 1 vez por pessoa (localStorage + coluna `moradores.novidades`).
### Ideias pendentes
Braço do sofá por cima das pernas e lugares fixos no sofá; aumentar cadeira/poltrona; interiores das lojas em outra dimensão; ambulância.

### Para o próximo chat (17/11/2026, fim da quarta sessão)
- Anexar: `CONTEXTO.md`, `index.html` (v20261117g), `banco.sql`, `novidades.sql` e `pix-funcao.ts`.
- SQL desta atualização em partes pequenas para o celular: `sql-celular/novidades-01..05.sql`. Banco completo em partes: `sql-celular/banco-01..16.sql`.
- Combinado novo de trabalho: primeiro mandar FOTO + link do arquivo de teste (Artifact). Só mandar `site.zip` e `index.html` quando o usuário aprovar. Respostas curtas.
- Arquivo de teste: cópia do index com ONLINE=false e um setInterval que libera nível 30, R$ 300 mil, todos os carros, VIP, Top 1 e põe o personagem na frente de uma mansão.
- Pendências: veículo para o repositor (oferecido), boneco maior no mapa (oferecido), ambulância (.max), braço do sofá por cima das pernas, interiores das lojas.

## SITUAÇÃO EM 18/11/2026 (quinta sessão) — LEIA PRIMEIRO
Versão VERSAO_JOGO v20261118b. Ramo `claude/new-session-zudz0a`. Subir: `site.zip` (index + 3 músicas) e rodar `novidades.sql` (etapas 21 a 23).
### O que entrou
- Provador fechado: só peças grátis/compradas/em uso (cliente) + `criar_morador` confere `guarda_roupa` (`_confere_roupas`, `_vis_nums`). Quem já jogava ganhou as peças que usava.
- Todos os carros refeitos no Blender (fotos 320 px, 32 ângulos) com **rodas girando** (4 fotos só das rodas por carro, `RODA_IMG`, trocadas pela distância andada). Pintura sem pegar faróis. Opala e Jipe Renegado com modelos novos. Ferrarini (`gto`, Ferrari) na loja do Pix no lugar da Lambordini (`neon`, agora só com VIP). Nomes: Rover (`esportivo`), Lambordini (`neon`), Jipe Renegado (`jipe`).
- Tamanhos com a Hilux como base (viatura -12%, Rover -11%, Lambordini -10%, SW4 -9%) em `CAR_ESC`.
- Mercadinho: entrega na frente das barracas (personagem ficava escondido). Policial e prefeito descem da viatura/Duster (`trabalho.ape`). Painel de tarefas e missão no canto esquerdo e minimizáveis (`#painelEsq`).
- Chat do prefeito só levemente amarelo (só emoji 🏛️, sem a palavra prefeito). Tiradas as músicas Forró do Dragão e Festa Boa.
- Scripts do estúdio de fotos (render2.py, auto.py, folha.py, integra.py) ficaram no scratchpad e se perdem; o código de faróis acesos (`LUZ_IMG`, `LUZES_FRAME`) já está no jogo mas sem as fotos de luz.
- **Relógio do jogo:** `SPEED=1` → 1 hora do jogo = 1 minuto real, 1 dia = 24 minutos (antes 8).
- **Medidor de desempenho** (⚙️ → 📊 Mostrar desempenho, `CFG.perf`, `perfTick`): quadros por segundo e travadas (quadro > 0,1 s) nos últimos 10 s. O computador de teste desenha sem placa de vídeo e não serve para medir; trocar degradês da luz por imagem pronta PIOROU aqui e foi desfeito.
### Pendências
1. Faróis acendendo ao dirigir (falta tirar as fotos de luz de cada carro).
2. Kombi e Fusca Dourado: o usuário vai mandar os modelos.
3. **Curva de XP (fazer quando for para a Play Store):** níveis 1–9 custam 70% de hoje, 10–19 ×0,91, 20–34 ×1,18, 35–50 ×1,54 (passo de hoje = 50×n). Converter o XP de cada jogador para não cair de nível.
4. Fechar compra da Lambordini direto pelo Pix (o produto `carro_neon` ainda existe no banco).

## SITUAÇÃO EM 21/11/2026 (sexta sessão) — LEIA PRIMEIRO
Versão VERSAO_JOGO **v20261121e** (ramo `ccr-ecf86c6e-oy7n3d`). Anexar no chat novo: `CONTEXTO.md`, `index.html`, `banco.sql`, `novidades.sql`, `pix-funcao.ts`.
**NO SERVIDOR HOJE:** o usuário subiu a versão v20261119g com o XP 2x e rodou as **etapas 21 a 24** (provador, Rover/Jipe Renegado, Ferrarini no Pix, XP 2x). Ou seja: no ar estão a correção da tela preta (incluindo preso dentro de casa), sirene e giroflex Dupla/Rápida e os faróis da época (com LED em vários carros).
**AINDA NÃO SUBIDO:** tudo depois disso (v20261120a até v20261121e): faróis novos (só Hilux com LED), condomínio, imobiliária, casas 50% mais caras. Para subir: 1) rodar `novidades.sql` (agora só a **etapa 25**) no Supabase; 2) subir `site.zip` (index + charrete.mp3, futilidades-entre-nos.mp3, o-campeao.mp3) no Cloudflare.
Combinado de trabalho: primeiro FOTO + link de teste (Artifact privado https://claude.ai/artifact/PVH5qqowD4CYbPN7k8qLV7, cópia com ONLINE=false); só mandar site.zip/index.html quando ele aprovar. Respostas curtas, em português simples. Pesquisar na internet antes de fazer as coisas (ele pede sempre).

### O que entrou nesta sessão
- **Tela preta corrigida:** `frame()` com try/catch (`erroTela` mostra aviso "⚠️ Erro na tela"); posição NaN volta para o bar; quem estava "dentro de casa" (eu.rm) e foi levado para longe (emprego, hospital, carro) sai da sala sozinho (era a causa da tela preta).
- **XP por tarefa:** `t.xp/5` (2x). Função `tarefa_feita` no banco e `J.xp/5` no index.
- **Faróis:** sistema `FAROL_POS` (posição 3D por carro, calibrada nas fotos), `FAROL_FORMA` (formas), `farolQuadro` (camada de luz por ângulo, recortada pela lataria, em cache) e `_farol3` (formas com pontos 3D de verdade: '3l' linha, '3p' polígono). O farol do lado de lá some quando o carro vira (`longe`). **Hoje só a Hilux (kombi_tonhao) tem LED na frente: o "U" no projetor e o risquinho do meio.** Os outros carros estão sem farol na frente (só lanternas traseiras, mais fortes ao frear). O usuário vai mandar as fotos de frente desenhadas com o LED (mandei `frente-*.png` dos 16 veículos; medidas do recorte em `extras/frentes-medidas.json`: sprite, box, escala 5x do quadro 24) para eu copiar o LED do jeito que ele desenhar.
- **Sons de motor:** `Som.motor` com `MOT` (cilindros, rpm, harmônicos, batida de diesel, turbo). Os DIESEL (SW4, Hilux, viatura, Frontier, Amarok, caminhões) ele aprovou. Os outros (moto, Fusca, Opala, Sedã, Rover, Lambordini, Ferrarini, Renegade) ele achou "mosquito": combinamos usar gravações reais grátis (Pixabay/Freesound). A rede do ambiente bloqueia esses sites (ele liberou os domínios, mas os sites barram robôs) → **ele vai baixar e mandar os MP3**. Não usar sons de mods do FiveM/GTA (direito autoral) — já recusei.
- **Viatura:** sirene sintetizada (`Som.sirene`: longa/wail e rápida/yelp) e giroflex no modelo 3D (`GIRO_PTS`, `giroflexV`: barra do teto + LEDs da grade e da traseira). Painel na caixa do emprego (`#viatPainel`): 🚨 Desl./Dupla/Rápida e 📢 Desl./Longa/Rápida, independentes. Rede: `gf = luz + 10×sirene`. (Ele preferiu a versão "Dupla/Rápida", sem efeitos no chão.)
- **Condomínio Vila Tonhão** (na mata, à esquerda da lagoa, x0..30 y-19..-4): muro com grade, portaria, **2 entradas com cancela** (leste pela estrada de terra; sul pela rua da coluna 12/13), pátio/estacionamento (dá para entrar de carro), 4 blocos de 4 andares (`BLOCOS`, desenho `blocoFatia`), playground, churrasqueira, quadra. Estrada de terra liga o fim do asfalto (coluna 34) ao condomínio e à lagoa. **64 apartamentos** (`APTOS`): número no banco = 1000 + bloco×100 + andar×10 + final (apto 101 do bloco A = 1111). Blocos A, B, C = kitnet pequena (4.000 ou 250/semana); bloco D = 2 quartos (6.000 ou 350/semana). Interiores em outra dimensão (`SALAS.kit`, `SALAS.ap2`, canto nordeste). Perto da porta do bloco: "🏢 Bloco X: apartamentos" → números (🔑 livre, 🏠 seu, 🔓 destrancado, 🔒 trancado → **campainha**: eventos `campainha`/`campOk`/`campNao`; o dono autoriza).
- **Regras:** casa OU apartamento (comprar casa deixa o apto vago, com aviso antes); aluguel cobrado sozinho (`cobrar_aluguel`, ao entrar e a cada 10 min); 3 dias de atraso = perde o apto e os móveis são vendidos pela metade. **Casas da cidade 50% mais caras** (12 mil, 18 mil, 30 mil, mansão 135 mil).
- **Imobiliária** (ao lado da Igreja, x38 y41): interior em outra dimensão (`IMOB`, `SALAS.imob`, móveis fixos) com a **Corretora Zélia/Corretor Zé** (NPC, nome conforme o sexo do boneco) que dá bom dia/boa tarde/boa noite a quem entra. "Falar com o corretor" → Comprar/Alugar → mapa com casas livres (preço) e o condomínio (blocos com apartamentos livres). **Compra só na imobiliária**; casas livres podem ser visitadas por dentro (sem decorar).
- **SQL (etapa 25, testado num PostgreSQL local):** colunas `casas.alugada`, `aluguel_ate`, `valor_aluguel`; `tipo` recriado (inclui 'apto'); tabela `migracoes`; funções `_vagar_apto`, `_limpa_aptos`, `_pegar_apto`, `comprar_apto`, `alugar_apto`, `sair_apto`, `cobrar_aluguel`, `comprar_casa` nova. No `banco.sql` os preços das casas já estão ×1,5 na lista; no `novidades.sql` a multiplicação roda uma vez só (marcada em `migracoes`).

### Pendências / próximos passos
1. Ele aprovar e subir (SQL primeiro, depois site.zip).
2. LED dos faróis dos outros carros conforme os desenhos dele.
3. Sons reais dos carros a gasolina (ele manda os MP3).
4. Interiores das lojas em outra dimensão (ele quer que todas, inclusive a Loja de Roupas, virem salas em outra dimensão; só o bar fica como está).
5. Curva de XP para a Play Store (anotada na sessão anterior).

## SITUAÇÃO EM 22/11/2026 (sétima sessão) — LEIA PRIMEIRO
Versão VERSAO_JOGO **v20261122z** (ramo `ccr-e8b9720b-5amd2g`). O usuário rodou a **etapa 25** no Supabase nesta sessão. Para subir: `site.zip` = `index.html` + `musicas/` + **`sons/` (pasta nova, obrigatória)**. Nenhum SQL novo nesta versão.
Teste sem servidor (Artifact privado, ONLINE forçado false, entra direto, botão "🧪 Carros" com todos os veículos inclusive de trabalho): https://claude.ai/artifact/C4QSmTKE8EojyVzA72WX4d
### O que entrou
- **Desempenho:** `imageSmoothingQuality` do ctx principal 'high' → 'low' (35 → 48 qps no teste). Pendentes: luz da noite mais leve; guardar prontos prédios/muros (maior ganho que sobra).
- **Tela nova:** topo: nível, dinheiro e hora; embaixo do nível o botão **🟢 N online** (`#irBtn`, abre o painel Ir para); 🏆 ranking ao lado da hora (`#rankTop`); dinheiro grande mostrado curto (R$ 300 mil, R$ 1,25 mi); peixes 🐟 na linha de baixo (`#peixeP`); fome/sede só abaixo de 50%; painel **🔍 Ir para** (`#mIr`: moradores, sala, busca, 📍 Ir até mim, 🏆, lugares em botões). Menu **☰ no canto direito, acima do joystick (ou embaixo à direita com joystick na esquerda), abrindo para cima** com 7 botões (zoom +/−, 📷 e 📍 saíram; 🛡️ Admin foi para ⚙️). ⚙️ tem **🕹️ Joystick Esquerda/Direita** (`CFG.joy`, classe `body.joyEsq`; o menu vai para o outro canto).
- **Faróis:** `FAROL_FORMA` dos 6 carros marcados (sw4, viatura, kombi_tonhao, duster, neon, caminhonete) refeito pelas marcações amarelas do usuário: frente em '3p' branco (círculos, setas, LED, milha) e traseira '3p' vermelho (copiado idêntico). Jeep (jipe), Ferrari (gto) e Rover (esportivo) ficaram com o LED dos riscos vermelhos anteriores. Farol do outro lado aparece na diagonal (`longe` com 1.2×|cy|). O usuário aprovou.
- **Novidades:** `NOVID='v20261122'` (XP em dobro, imobiliária, condomínio, jogo mais leve/tela nova). Trava contra abrir duplicada.
- **Sons reais de motor** (`sons/*.mp3`, trechos de 4 s em loop, `GRAV`/`GRAV_RPM`/`gravacao()` dentro de `Som.motor`): fusca (e fusca_ouro), sedan (e jipe), opala, esportivo, neon, gto, moto, diesel (sw4, kombi_tonhao, caminhonete, viatura). Volume .2 e tom suave (aprovado). Frontier, Duster da prefeitura e caminhões continuam sintetizados.
- **Relógio do jogo:** `SPEED=1` → 1 hora do jogo = 1 minuto real, 1 dia = 24 minutos (antes 8).
- **Polícia:** patrulha sem limite (`trabalho.ronda`: um ponto azul atrás do outro, opcional); a cada 90 s paga R$ 50 + 20 XP pela função nova `ronda_policia` (**ETAPA 26**, `novidades.sql`; limite de 85 s no servidor). A viatura não some mais.
- **Entregas pela cidade:** `pontosCidade()`/`pontoCidade()` (calçada G.WALK colada em rua) para padeiro, operário (fábrica) e lixeiro.
- **Arquivo de teste:** o "trapaça" também atualiza o banco local (`L.me`), então os trabalhos de nível alto abrem.
- **Medidor de desempenho** (⚙️ → 📊 Mostrar desempenho, `CFG.perf`, `perfTick`): quadros por segundo e travadas (quadro > 0,1 s) nos últimos 10 s. O computador de teste desenha sem placa de vídeo e não serve para medir; trocar degradês da luz por imagem pronta PIOROU aqui e foi desfeito.
- **Play Store (preparado):** app TWA em `app-android/` (Bubblewrap; pacote `br.com.viladotonhao.app`, targetSdk 35), `.aab` e `.apk` assinados em `entrega/app/` com a chave `cidade-do-tonhao.keystore` (NÃO vai pro git; o usuário guarda). `.well-known/assetlinks.json` tem o SHA-256 da chave de upload; falta acrescentar o SHA-256 da chave de assinatura do Google (Play Console → Integridade do app). Guia completo: `GUIA-PLAY-STORE.md`. Imagens da loja em `entrega/loja/`. Para compilar de novo: Android SDK em /opt/android-sdk, `./gradlew bundleRelease` (usar o espelho maven-central.storage-download.googleapis.com; Maven Central dá 429) e assinar com jarsigner.
- **App sem loja Pix:** com `?app=1` (start_url do app) ou referrer android-app, `NO_APP` esconde o 💎 e bloqueia `abrirLoja`/`comprarPix` (regra de pagamentos do Google). Site normal.
- **Excluir conta (ETAPA 27):** função `excluir_conta()`, botão em ⚙️ e página `excluir-conta.html`. **Privacidade:** `privacidade.html` (contato: chat do jogo ou e-mail da página na Google Play).
- **Bloquear jogador:** botão 🔇 no cartão; lista `BLOQ` no aparelho (some chat, balões, convites, propostas, sinuca).
- **Menos travadas:** chão em blocos de 256 (antes 512) e 1 bloco novo por quadro; camada de faróis 320 px (antes 640); brilho do farol do outro lado só quando visível.
- **Manifest/ícones:** `manifest.webmanifest`, `icones/` (emoji 🍺 da fonte Noto).
- **Passe da Temporada (ETAPA 28):** tabelas `passe_temporadas`, `passe_premios`, `passe_jogador`; temporada T1 "Natal na Vila" até 01/01/2027; 20 níveis × 300 pontos (`PASSE_NV`; ~7 h de trabalho, ~2 semanas); tarefa = 2 a 15 pontos conforme o tempo do emprego (`_pontos_tarefa` no banco, `PONTOS_JOB` no cliente), patrulha = 15, VIP +50% (`_passe_pontos`, chamado em `tarefa_feita` e `ronda_policia`); `meu_passe()`, `resgatar_passe(nivel,trilha)`; prêmios por `_dar_premio` (dinheiro, estampa, roupa/calca/calcado/chapeu/extra para os dois sexos no `guarda_roupa`). Premium = produto Pix `passe_T1` (R$ 9,90, tipo 'passe' no `_entregar`). Cliente: `PASSE_T1` (cópia dos prêmios para o modo offline), `abrirPasse`/`pintaPasse`, botão 🎟️ no menu. Nova temporada = inserir em `passe_temporadas` + `passe_premios` + produto `passe_T2` e atualizar o cliente.
- **VIP turbinado:** `vip_mensal` (presente por mês até 2027-04) + `presente_vip()`/`vip_info()`; botões 🎁 Presente do mês e 🏠 Ir para casa (`irParaCasa`) em ⚙️; produto `vip90` (R$ 39,90). Novidades `NOVID='v20261125'` com 2 páginas novas.
- **Itens exclusivos (índices 30-39, `OPC.chapeu.exc`, `excOf`)**: gorro de Papai Noel (30, grátis nível 5) e gorro brilhante (31, premium nível 1; todos veem brilhando). Não vendem (`preco_roupa` 999999, `comprar_roupa` recusa).
- **Prêmio final do passe:** `{"carro":"natal"}` (premium nível 20). Bloqueado até `passe_temporadas.carro_pronto = true` e até existir `CARS_PREMIUM.natal` no cliente. Quando o usuário mandar o carro: adicionar o sprite com id `natal`, `CARS_PREMIUM.natal` e rodar `update passe_temporadas set carro_pronto = true where id = 'T1'`.
- **Tela do passe nova** (estilo Fortnite/Clash): vitrine com carro (silhueta "?") e gorro, aviso "nunca mais voltam", trilha horizontal grátis/premium com miniaturas do próprio boneco (`thumbPremio`). Loja VIP com quadro de benefícios e a Lambordini desenhada.
- **Roupas VIP novas** (no fim de `vipm`/`vipf`, 53-56): Bomber dourada com pelo, Puffer neon (gomos), Sobretudo de veludo (até o joelho), Smoking com capa (m) / vestido de lantejoulas (f), com formatos próprios desenhados fora do corpo; tênis neon (calçado 51) e boné neon (chapéu 52). **Estampas redesenhadas** (mesmos índices).
- **Brilho no chão (rastro):** coluna `moradores.rastro` ('ouro' VIP, 'natal' do passe nível 12 premium = `guarda_roupa(rastro,1)`, 'nenhum'); `usar_rastro()`; `_estado` devolve rastro; outros jogadores leem no select de perfil. Desenho em `desenhaBrilhos` (cores por `b.k`).
- **Guarda-roupa** (`abrirGuarda`, modal `#mGuarda`): abas Roupas/Baixo/Calçados/Cabeça/Acessórios/Estampas/Brilho com miniaturas (`grThumb`), só peças que a pessoa tem (`provLivre` + VIP + exclusivas), 3 looks salvos no aparelho, "🎨 Cores e cabelo" abre o provador antigo (`abrirProvadorVisual`). Botão "👕 Guarda-roupa" no cartão do próprio jogador.
- **Mochila nova** (`abrirMochilaNova`, `#mMochila`): abas Itens (grade de 20 espaços com quantidade e botão Usar), Roupas (abre o guarda-roupa), Carros (dirigir/estacionar) e Pets.
### Pendências
000. Carro exclusivo do passe (o usuário vai mandar).
00. Confirmar se o usuário rodou a ETAPA 28 (`novidades.sql`). Antes: ETAPAS 26 e 27 já rodadas.
0. Confirmar se o usuário rodou as ETAPAS 26 e 27 e se `/.well-known/assetlinks.json` abriu no site depois de subir (o Cloudflare pode ignorar pasta com ponto).
1. Desempenho itens 2 e 3 (o usuário reclamou que o jogo trava).
2. Interiores das lojas em outra dimensão. 3. Curva de XP para a Play Store.
