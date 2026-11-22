#!/usr/bin/env bash
# Instala o Android SDK (só precisa para gerar app). ~2 minutos.
set -e
mkdir -p /opt/android-sdk/cmdline-tools && cd /tmp
curl -sSL -o clt.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q -o clt.zip -d /opt/android-sdk/cmdline-tools && rm -rf /opt/android-sdk/cmdline-tools/latest && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest
yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android-sdk "platforms;android-36" "build-tools;35.0.0" "platform-tools" >/dev/null
echo "SDK instalado em /opt/android-sdk"
