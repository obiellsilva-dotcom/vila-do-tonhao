# Guia: lançar a Cidade do Tonhão na Play Store

## O que já está pronto
| Arquivo | Para que serve |
|---|---|
| `cidade-do-tonhao.aab` | O app que vai para a Play Store (pacote `br.com.viladotonhao.app`, versão 1.0.0, Android 15/nível 35) |
| `cidade-do-tonhao-teste.apk` | Para instalar direto no celular e testar antes |
| `cidade-do-tonhao.keystore` + `senha-da-chave.txt` | **A chave do app. Guarde em 2 lugares seguros (Google Drive + pendrive).** Sem ela não dá para atualizar o app. Nunca mande para ninguém. |
| `loja/icone-512.png`, `loja/destaque-1024x500.png`, `loja/print1..4.png` | Imagens da página da loja |
| Site: `privacidade.html`, `excluir-conta.html`, `manifest.webmanifest`, `icones/`, `.well-known/assetlinks.json` | Vão junto no `site.zip` |

O app abre o site viladotonhao.com.br em tela cheia (TWA). Atualizou o site, atualizou o app.

## Antes de tudo
1. Rodar o `novidades.sql` no Supabase (etapas 26 e 27).
2. Subir o `site.zip` no Cloudflare.
3. Conferir no navegador que estes endereços abrem:
   - https://viladotonhao.com.br/privacidade.html
   - https://viladotonhao.com.br/excluir-conta.html
   - https://viladotonhao.com.br/.well-known/assetlinks.json  ← se não abrir (o Cloudflare às vezes ignora pastas que começam com ponto), o app mostra uma barra de endereço em cima: funciona, mas fica feio. Me avise que eu faço o Worker do Cloudflare entregar esse arquivo.

## Passo a passo no Google Play Console
1. **Conta de desenvolvedor**: play.google.com/console → criar conta pessoal (taxa única de US$ 25, pede documento).
2. **Criar app**: nome "Cidade do Tonhão", idioma Português (Brasil), Jogo, Gratuito.
3. **Configurar o app** (lista do painel):
   - **Política de privacidade**: https://viladotonhao.com.br/privacidade.html
   - **Acesso ao app**: marque que algumas funções precisam de login. Crie uma conta de teste no jogo (e-mail e senha) e informe lá para o revisor do Google entrar.
   - **Anúncios**: Não tem anúncios.
   - **Classificação de conteúdo**: questionário IARC. Responda: interação entre usuários **sim** (chat), compartilha localização **não**, compras digitais **sim**, referência a álcool **sim** (bar/cerveja, sem incentivo). Deve sair 12 ou 14 anos.
   - **Público-alvo**: 13 anos ou mais (não marcar crianças).
   - **Segurança dos dados**: coleta e-mail (conta), nome e fotos (perfil), mensagens (chat), histórico de compras. Tudo criptografado em trânsito. O usuário pode pedir exclusão: **https://viladotonhao.com.br/excluir-conta.html**. Não compartilha com terceiros para anúncios.
   - **Exclusão de conta**: link https://viladotonhao.com.br/excluir-conta.html
4. **Página da loja**:
   - Descrição curta (até 80): `Trabalhe, compre casa e carro e faça amigos no Bar do Tonhão!`
   - Descrição completa:
     > Bem-vindo à Cidade do Tonhão, uma cidadezinha brasileira online onde você joga junto com outras pessoas!
     > 🍺 Passe no Bar do Tonhão, jogue sinuca e converse no chat.
     > 💼 Trabalhe de garçom, padeiro, policial, médico, lixeiro e muito mais, ganhe dinheiro e suba de nível.
     > 🏠 Compre ou alugue casa e apartamento e decore com móveis.
     > 🚗 Compre carros, escolha a cor e saia dirigindo pela cidade, de dia e de noite.
     > 👕 Monte seu visual com roupas, chapéus e joias.
     > 🏛️ Chegue ao nível 30 e vire prefeito da cidade!
   - Ícone: `loja/icone-512.png` · Recurso gráfico: `loja/destaque-1024x500.png` · Capturas de tela: `loja/print1..4.png`
5. **Teste fechado (obrigatório para conta pessoal criada depois de nov/2023; conta de empresa não precisa, mas exige número D-U-N-S)**: Testes → Teste fechado → criar faixa → enviar o `cidade-do-tonhao.aab` → adicionar **pelo menos 12 testadores** (e-mails do Gmail deles) → eles precisam aceitar o convite pelo link e manter o app instalado por **14 dias seguidos**.
6. **Assinatura do Google (importante)**: ao enviar o .aab, o Google assina o app com a chave dele. Depois vá em **Configuração → Integridade do app → Assinatura do app** e copie o **SHA-256 da chave de assinatura do app**. Me mande esse código: eu coloco no `assetlinks.json` do site (senão aparece a barra de endereço no app baixado da loja).
7. Passados os 14 dias: **Produção → Solicitar acesso à produção** → responder o questionário → enviar para revisão (alguns dias).

## Pagamento (já resolvido do jeito mais seguro)
O Google exige que VIP, carros e pets comprados **dentro do app** usem o pagamento do Google (taxa de 15%). Por isso, **quando o jogo é aberto pelo app, a loja de Pix (💎) fica escondida**. No site tudo continua igual, e quem compra pelo site recebe no app também (é a mesma conta). Não coloque na descrição da loja nada mandando comprar pelo site (o Google não deixa).
Pesquisado em 17/11/2026: no Brasil o Google só deixa "sistema alternativo de faturamento" para apps que **não são jogos**; jogos têm que usar o faturamento do Google Play. Por isso o Pix fica só no site. Se no futuro quiser vender dentro do app, dá para integrar o pagamento do Google Play (que também aceita Pix para compras únicas).
