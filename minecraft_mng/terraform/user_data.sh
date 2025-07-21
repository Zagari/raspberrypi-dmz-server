#!/bin/bash
# Sai imediatamente se qualquer comando falhar
set -e

echo "--- Iniciando script de User Data ---"

# 1. ATUALIZAÇÃO DO SISTEMA
echo "Atualizando pacotes do sistema..."
apt-get update -y
apt-get upgrade -y

# 2. INSTALAÇÃO DE DEPENDÊNCIAS BÁSICAS
echo "Instalando dependências (curl, gnupg, git)..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    python3-pip

# 3. LIMPEZA DE VERSÕES ANTIGAS DO DOCKER (garante um ambiente limpo)
echo "Removendo versões antigas do Docker, se existirem..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# 4. INSTALAÇÃO DO DOCKER A PARTIR DO REPOSITÓRIO OFICIAL
echo "Configurando o repositório oficial do Docker..."
# Cria o diretório de chaves com as permissões corretas
install -m 0755 -d /etc/apt/keyrings
# Baixa e adiciona a chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# Garante que a chave seja legível por todos
chmod a+r /etc/apt/keyrings/docker.gpg

# Adiciona o repositório do Docker à lista de fontes do APT
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. INSTALAÇÃO DO DOCKER ENGINE
echo "Instalando Docker Engine..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. INSTALAÇÃO DE DEPENDÊNCIAS PYTHON PARA ANSIBLE
echo "Instalando bibliotecas Python para os módulos Docker do Ansible..."
pip3 install docker docker-compose

# 7. CONFIGURAÇÃO PÓS-INSTALAÇÃO
echo "Configurando Docker para o usuário ubuntu..."
# Adiciona o usuário 'ubuntu' ao grupo 'docker' para executar comandos docker sem sudo
usermod -aG docker ubuntu
# Habilita o serviço Docker para iniciar no boot
systemctl enable docker.service
systemctl start docker.service

echo "--- Script de User Data concluído com sucesso! ---"
