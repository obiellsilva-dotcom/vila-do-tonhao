#!/usr/bin/env bash
# Publica o jogo no ar: copia index.html (e páginas) do ramo de trabalho para site/public no ramo main.
# O Cloudflare (Worker "viladotonhao", ligado ao GitHub, pasta /site) publica sozinho em 1-2 minutos.
# SÓ RODE COM O "pode"/"vamos subir" DO DONO.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
RAMO=$(git branch --show-current)
V=$(grep -o "VERSAO_JOGO='[^']*'" index.html | head -1 | cut -d"'" -f2)
echo "Versão a publicar: $V (ramo de trabalho: $RAMO)"
git diff --quiet && git diff --cached --quiet || { echo "Há mudanças sem commit. Faça commit antes."; exit 1; }
# confere se o JavaScript não tem erro de sintaxe
node -e "const s=require('fs').readFileSync('index.html','utf8');const re=/<script>([\s\S]*?)<\/script>/g;let m,n=0;while((m=re.exec(s))){try{new Function(m[1])}catch(e){console.log('ERRO JS:',e.message);n++}}process.exit(n?1:0)"
TMP=$(mktemp -d); for f in index.html privacidade.html excluir-conta.html manifest.webmanifest; do cp "$f" "$TMP/"; done
cp .well-known/assetlinks.json "$TMP/assetlinks.json"; mkdir -p "$TMP/icones"; cp icones/* "$TMP/icones/"
git fetch -q origin main
git checkout -q -B main origin/main
for f in index.html privacidade.html excluir-conta.html manifest.webmanifest; do cp "$TMP/$f" site/public/; done
cp "$TMP/assetlinks.json" site/public/.well-known/assetlinks.json; cp "$TMP/icones/"* site/public/icones/
git add site
if git diff --cached --quiet; then echo "Nada mudou no site."; else git commit -qm "Site $V"; git push -q origin main; echo "Enviado ao main."; fi
git checkout -q "$RAMO"
echo "Esperando o Cloudflare publicar..."
for i in $(seq 1 16); do sleep 20; if curl -s https://viladotonhao.com.br/ | grep -q "$V"; then echo "NO AR: $V"; exit 0; fi; done
echo "Ainda não apareceu. Confira no Cloudflare (Workers & Pages > viladotonhao > Deployments)."
