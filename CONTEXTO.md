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
- `index.html` é a versão única e atual (VERSAO_JOGO v20261117b). A antiga "proposta" foi incorporada nele; NÃO use mais `extras/proposta-index.html`.
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
Versão VERSAO_JOGO v20261117b. Ramo `ccr-c5db5bd8-0bdems`. Para subir: `index.html` + `musicas/` (site.zip) e rodar `novidades.sql` (pequeno) no Supabase.
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
