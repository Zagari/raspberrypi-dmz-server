#!/bin/bash

# --- Configuração ---
# Interrompe o script imediatamente se qualquer comando falhar.
set -e

# Nome da imagem e tag para fácil modificação
IMAGE_NAME="rpi-nginx"
TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
TAR_FILENAME="${IMAGE_NAME}.tar"

# --- Lógica Principal ---

# Detecta a arquitetura do hardware da máquina
HOST_ARCH=$(uname -m)

# Verifica se a arquitetura é armv7l (padrão para Raspberry Pi 2/3)
if [[ "$HOST_ARCH" == "armv7l" ]]; then
    # --- MODO NATIVO (Executando no Raspberry Pi) ---
    echo "✅ Detectada arquitetura ARMv7 ($HOST_ARCH). Executando build nativa..."

    # Constrói a imagem Docker localmente. É mais rápido e simples.
    docker build -t "$FULL_IMAGE_NAME" .

    echo "🎉 Build nativa concluída com sucesso!"
    echo "A imagem '$FULL_IMAGE_NAME' está pronta para ser usada diretamente no seu Raspberry Pi com 'docker run'."
    echo "Não é necessário salvar em .tar nem carregar a imagem."

else
    # --- MODO CROSS-COMPILE (Executando em Mac/PC) ---
    echo "🖥️  Detectada arquitetura não-ARM ($HOST_ARCH). Executando build cross-compile para linux/arm/v7..."

    # Usa buildx para compilar para a plataforma ARMv7
    # O --output type=docker carrega a imagem resultante no daemon Docker local
    docker buildx build --platform linux/arm/v7 -t "$FULL_IMAGE_NAME" . --output type=docker

    echo "✅ Build cross-compile concluída com sucesso!"
    
    echo "📦 Salvando a imagem como arquivo '$TAR_FILENAME' para transferência..."
    
    # Salva a imagem recém-construída em um arquivo .tar
    docker save "$FULL_IMAGE_NAME" > "$TAR_FILENAME"
    
    echo "🎉 Imagem salva como '$TAR_FILENAME'."
    echo "➡️  Agora, transfira este arquivo para o seu Raspberry Pi e carregue-o com o comando:"
    echo "    docker load < $TAR_FILENAME"
fi

echo ""
echo "Script finalizado com sucesso."