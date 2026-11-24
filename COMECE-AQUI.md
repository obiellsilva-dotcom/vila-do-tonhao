# Como abrir um chat novo — Vila do Tonhão (outra conta do Claude)

## Antes de tudo (uma vez só, na conta nova)
1. Entre no **claude.ai** com a conta nova.
2. Ligue o **GitHub** nessa conta: claude.ai → Configurações → **Conectores / GitHub** → conectar com o **mesmo GitHub** de sempre (`obiellsilva-dotcom`).
   - Se pedir, instale o **app do Claude no GitHub** e dê acesso ao repositório **vila-do-tonhao**.
3. Abra o **Claude Code** (claude.ai/code) e comece uma sessão nova escolhendo o repositório **`obiellsilva-dotcom/vila-do-tonhao`**.
   - Se der para escolher o ramo, escolha **`claude/new-session-4u8s9f`**.

> Se não der para ligar o GitHub, anexe o arquivo **`pacote-novo-chat.zip`** no chat (tem o jogo, o banco e as ferramentas; as músicas ficam só no GitHub).

## Mensagem para colar como primeira mensagem
```
Olá! Sou o dono do jogo Vila do Tonhão. Não sou programador, uso só o celular e tenho pouco limite de uso.
Responda em português simples, curto e passo a passo.

1. Busque o ramo claude/new-session-4u8s9f do repositório (git fetch origin claude/new-session-4u8s9f) e trabalhe a partir dele.
2. Leia o arquivo LEIA-PRIMEIRO.md inteiro, principalmente a seção 0 (como trabalhar), a 3 (situação agora) e a 10 (minhas regras).
3. Depois me pergunte só o que estiver pendente e me diga qual é o próximo passo.

Regras importantes:
- Teste tudo antes de me entregar (app, jogo e SQL).
- Só publique no site quando eu disser "vamos subir". Antes, me mande foto e link de teste.
- Não mexa no ramo main sem eu dizer "pode".
- Para subir o site use ferramentas/subir-site.sh (é automático, eu não preciso mandar arquivo).
- Só me peça a chave do app quando for gerar uma versão nova do app.
```

## Quando for preciso gerar app novo (raro)
Anexe no chat **`vila-do-tonhao.keystore`** e diga a **senha** (está no `senha-da-chave.txt`). Só nessa hora.

## Guarde em lugar seguro (Drive + pendrive)
- `vila-do-tonhao.keystore` e `senha-da-chave.txt` (sem eles não dá para atualizar o app nunca mais).
- O arquivo `.json` da conta de serviço do Google **não precisa guardar**: ele já está salvo no Supabase.
