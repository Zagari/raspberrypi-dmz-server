#!/bin/bash

# Script com instruções para configurar o Docker no Raspberry Pi 2 e executar o container
echo "Instruções para instalar o Docker e executar o container no Raspberry Pi 2"
echo "======================================================================"
echo ""
echo "Este script contém apenas instruções. Você precisará executar os comandos manualmente no Raspberry Pi 2."
echo ""

cat << 'EOF'
PASSO 1: Instalar o Docker no Raspberry Pi 2
-------------------------------------------
Conecte-se ao Raspberry Pi via SSH e execute os comandos abaixo:

# Atualizar o sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependências
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Adicionar a chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/raspbian/gpg | sudo apt-key add -

# Adicionar o repositório do Docker
echo "deb [arch=armhf] https://download.docker.com/linux/raspbian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Atualizar a lista de pacotes
sudo apt-get update

# Instalar o Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Adicionar o usuário atual ao grupo docker (para executar Docker sem sudo)
sudo usermod -aG docker $USER

# Iniciar e habilitar o serviço Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verificar se o Docker está funcionando
docker --version

# IMPORTANTE: Faça logout e login novamente para que as alterações de grupo tenham efeito
# ou execute o comando abaixo para aplicar as alterações na sessão atual:
newgrp docker

PASSO 2: Transferir a imagem Docker para o Raspberry Pi 2
-------------------------------------------------------
No seu computador, onde você construiu a imagem:

# Transferir o arquivo rpi-ubuntu-iptables.tar para o Raspberry Pi
scp rpi-ubuntu-iptables.tar pi@IP_DO_RASPBERRY:~/

No Raspberry Pi:

# Carregar a imagem Docker
docker load < rpi-ubuntu-iptables.tar

# Verificar se a imagem foi carregada corretamente
docker images

PASSO 3: Executar o container Docker
----------------------------------
# Executar o container em modo daemon
docker run -d --name firewall-server --privileged rpi-ubuntu-iptables:latest

# Verificar se o container está em execução
docker ps

# Verificar os logs do container
docker logs firewall-server

PASSO 4: Gerenciar o container
----------------------------
# Parar o container
docker stop firewall-server

# Iniciar o container
docker start firewall-server

# Reiniciar o container
docker restart firewall-server

# Remover o container (precisa estar parado)
docker stop firewall-server
docker rm firewall-server

# Executar o container com reinicialização automática
docker run -d --name firewall-server --privileged --restart unless-stopped -p 80:80 rpi-ubuntu-iptables:latest

PASSO 5: Configurar o container para iniciar automaticamente na inicialização
---------------------------------------------------------------------------
O parâmetro --restart unless-stopped já garante que o container seja reiniciado 
automaticamente quando o Docker for iniciado, mesmo após reinicialização do sistema.

PASSO 7: Verificar o status do firewall
-------------------------------------
# Verificar o status do Iptables dentro do container
docker exec firewall-server iptables -L -n -v

# Se precisar ajustar regras do firewall no host Raspberry Pi:
sudo iptables -L -n -v                                  #Listar regras do firewall
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT    #Adicionar regra para aceitar conexões na porta 8080   ''
sudo iptables -A INPUT -j DROP                          #Bloquear todas as outras conexões            
sudo iptables -D INPUT -p tcp --dport 8080 -j ACCEPT    #Remover regra para aceitar conexões na porta 8080
sudo iptables-save > /etc/iptables.rules
EOF

echo ""
echo "Siga estas instruções para configurar o Docker e executar o container no Raspberry Pi 2."
echo "Após a execução, você poderá acessar o servidor web através do IP do Raspberry Pi."
