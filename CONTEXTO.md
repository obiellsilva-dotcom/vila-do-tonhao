# Cidade do Tonhão: contexto para continuar em outro chat

> Cole este arquivo no começo de uma conversa nova e anexe: `index.html` (versão no ar, 2.5D), `banco.sql`, `novidades.sql` e `pix-funcao.ts`.
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

## Prefeito e primeira missão
- **Prefeito = TOP 1 do ranking** (mais XP), trocado sozinho pelo banco (gatilho `prefeito_top1`, função `_atualiza_prefeito`). Não existe mais "assumir o cargo".
- **Primeira missão** para jogador novo (coluna `moradores.missao`: 0, 1, 2; função `missao_passo`): cartão dourado `#missao` + seta amarela. Missão 1: trabalhar de Repositor no Mercadinho e acertar 3 tarefas (bônus R$ 50). Missão 2: comprar comida (pão na Padaria). Dá para pular no ✕. Código: `msRender`, `msAlvo`, `msPasso`.
- Tutorial encurtado para 4 telas.
