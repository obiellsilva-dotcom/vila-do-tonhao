# Como abrir um chat novo — Cidade do Tonhão

## Passo a passo (pelo celular)
1. Abra o **Claude Code** e comece uma sessão nova com o repositório **`obiellsilva-dotcom/vila-do-tonhao`**.
2. Se der para escolher o ramo, escolha **`ccr-fe2fa98f-j3vukg`** (é onde está tudo).
3. Cole a mensagem abaixo como primeira mensagem.
4. Se o chat novo não conseguir abrir o GitHub, anexe o **`pacote-novo-chat.zip`**.

## Mensagem para colar no chat novo
```
Olá! Sou o dono do jogo Cidade do Tonhão. Não sou programador, uso só o celular e tenho pouco limite de uso.
Responda em português simples, curto e passo a passo.

1. Busque o ramo ccr-fe2fa98f-j3vukg do repositório (git fetch origin ccr-fe2fa98f-j3vukg e git checkout ccr-fe2fa98f-j3vukg) e continue trabalhando nele.
2. Leia o arquivo LEIA-PRIMEIRO.md inteiro, principalmente a seção 0 ("O que está pendente agora") e a seção 10 ("Regras do dono").
3. Depois me pergunte só o que estiver pendente (se eu já subi o site e rodei o SQL) e me diga qual é o próximo passo.

Regras importantes:
- Só me mande site.zip, index.html e SQL quando eu disser "vamos subir".
- Antes de eu subir, me mande foto e link de teste.
- Não mexa no ramo main sem eu dizer "pode".
- Nunca peça nem compartilhe a chave do app (cidade-do-tonhao.keystore e senha-da-chave.txt).
```

## O que ficou pendente (resumo)
- Confirmar se o **site v20261124t** subiu no Cloudflare (o aviso de "25 MiB" é do próprio .zip e pode ser ignorado se o deploy terminar).
- Confirmar se rodou o **SQL das partes 1 a 4** (etapas 31 a 35) no Supabase.
- Liberar a cópia da pasta **`tempo-real`** para o ramo **main** (conserta o número de jogadores online contando fantasmas).
- Subir a **v20261124u** no próximo "vamos subir".
- Depois: **Play Store** (seção 7 do LEIA-PRIMEIRO.md) e as ideias da seção 8.

## Guarde em lugar seguro (NÃO mande para ninguém, nem para o Claude)
`cidade-do-tonhao.keystore` e `senha-da-chave.txt`. Sem eles não dá para atualizar o app na Play Store.
