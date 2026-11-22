#!/usr/bin/env bash
# Publica o servidor ao vivo (pasta tempo-real/) copiando para o ramo main. O Cloudflare (Worker "vila-tempo-real") publica sozinho.
# SÓ RODE COM O "pode" DO DONO.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"; RAMO=$(git branch --show-current)
node -e "import('$(pwd)/tempo-real/src/index.js').then(()=>console.log('sintaxe ok'))"
git fetch -q origin main; git checkout -q -B main origin/main
git checkout "$RAMO" -- tempo-real; rm -rf tempo-real/.wrangler; git add tempo-real
if git diff --cached --quiet; then echo "Nada mudou."; else git commit -qm "Servidor tempo-real atualizado"; git push -q origin main; echo "Enviado. Teste: curl https://vila-tempo-real.obiellsilva.workers.dev/salas"; fi
git checkout -q "$RAMO"
