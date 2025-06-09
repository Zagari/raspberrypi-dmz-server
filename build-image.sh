#!/bin/bash

# Script para construir a imagem Docker para Raspberry Pi 2 (ARMv7)
echo "Iniciando build da imagem Docker para Raspberry Pi 2 (ARMv7)..."

# Construir a imagem Docker
docker build -t rpi-ubuntu-iptables:latest .

# Verificar se a build foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Build concluída com sucesso!"
    echo "Salvando a imagem como arquivo tar..."
    
    # Salvar a imagem como arquivo tar para transferência
    docker save rpi-ubuntu-iptables:latest > rpi-ubuntu-iptables.tar
    
    echo "Imagem salva como rpi-ubuntu-iptables.tar"
    echo "Você pode transferir este arquivo para o Raspberry Pi 2 e carregá-lo com:"
    echo "docker load < rpi-ubuntu-iptables.tar"
else
    echo "Erro na build da imagem Docker."
    exit 1
fi
