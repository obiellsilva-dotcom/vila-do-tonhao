#!/usr/bin/env bash
# Gera o .aab assinado para a Play Store. Precisa:
#   - Android SDK em /opt/android-sdk (ver ferramentas/instalar-android-sdk.sh)
#   - a chave: vila-do-tonhao.keystore + a senha (o DONO anexa no chat SÓ quando for gerar app; nunca commitar)
# Uso: ferramentas/gerar-app.sh /caminho/vila-do-tonhao.keystore 'SENHA' NOVO_CODIGO NOVO_NOME
#   ex.: ferramentas/gerar-app.sh /tmp/vila-do-tonhao.keystore 'xxxx' 23 2.0.5
set -euo pipefail
KS=$1; PW=$2; CODE=$3; NAME=$4
cd "$(git rev-parse --show-toplevel)/app-android"
sed -i -E "s/versionCode [0-9]+/versionCode $CODE/; s/versionName \"[^\"]+\"/versionName \"$NAME\"/" app/build.gradle
echo "sdk.dir=/opt/android-sdk" > local.properties
echo "Rodando os testes de abertura (Android 7 a 15)..."
./gradlew --no-daemon -q testReleaseUnitTest
for f in app/build/test-results/testReleaseUnitTest/*.xml; do grep -q 'failures="0" errors="0"' "$f" || { echo "TESTE FALHOU: $f"; exit 1; }; done
echo "Testes OK. Gerando o .aab..."
./gradlew --no-daemon -q bundleRelease
OUT=../entrega/app; mkdir -p $OUT; F=$OUT/vila-do-tonhao-v$CODE.aab
cp app/build/outputs/bundle/release/app-release.aab "$F"
jarsigner -keystore "$KS" -storepass "$PW" -keypass "$PW" "$F" tonhao >/dev/null
jarsigner -verify "$F" | grep -q "jar verified" && echo "PRONTO: $F (código $CODE, versão $NAME)"
