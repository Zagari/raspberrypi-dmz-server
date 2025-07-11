#!/bin/bash

# Interrompe o script imediatamente se qualquer comando falhar.
set -e

# Script para configurar o Docker no Raspberry Pi 2 e executar o container
echo "Instalação do Docker e execução do container no Raspberry Pi 2"
echo "======================================================================"
echo "Execute este script no seu Raspberry Pi 2 para configurar o Docker e executar o container."

echo "Pressione Enter para continuar..."
read

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root. Use 'sudo' para executar."
    exit 1
fi

echo "PASSO 1: Instalar o Docker no Raspberry Pi 2"
echo "-------------------------------------------"

echo "### Atualizando o sistema..."
sudo apt-get update
sudo apt-get upgrade -y

echo "### Instalando dependências..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common lsb-release

echo "### Adicionando a chave GPG oficial do Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/raspbian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "### Adicionando o repositório do Docker para Raspbian..."
# Para Raspberry Pi OS baseado em Debian Bookworm (ou Bullseye):
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/raspbian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "### Atualizando a lista de pacotes"
sudo apt-get update

echo "### Instalando o Docker Engine e o Docker Compose..."
# Adicionamos 'docker-compose-plugin' para instalar o Docker Compose V2
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "### Adicionando o usuário atual ao grupo docker (para executar Docker sem sudo)"
sudo usermod -aG docker $USER

echo "### Iniciando e habilitando o serviço Docker"
sudo systemctl enable docker
sudo systemctl restart docker

echo "### Verificando se o Docker está funcionando"
docker --version
docker compose version # Note o comando 'docker compose' sem hífen


echo "### Docker e Docker Compose instalados com sucesso!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! IMPORTANTE: Faça logout e login novamente para usar      !!"
echo "!! o Docker sem 'sudo', ou execute 'newgrp docker'        !!"
echo "!! em um novo terminal para aplicar as permissões agora.  !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "### Pressione Enter para continuar com o resto do script..."
read

cat << 'EOF'
PASSO 2: Construir a imagem Docker
======================================================================
Opção 1: Transferir a imagem Docker para o Raspberry Pi 2
----------------------------------------------------------------------
No seu computador, onde você construiu a imagem:

# Transferir o arquivo rpi-nginx.tar para o Raspberry Pi
scp rpi-nginx.tar pi@IP_DO_RASPBERRY:~/

No Raspberry Pi:

# Carregar a imagem Docker
docker load < rpi-nginx.tar

Opção 2: Construir a imagem diretamente no Raspberry Pi
----------------------------------------------------------------------
# No Raspberry Pi, execute o seguinte comando para construir a imagem Docker:

cd nginx/
docker build -t rpi-nginx:latest .
cd ../app
docker build -t rpi-webapp:latest .
ou...
EOF

# A partir daqui, usaremos 'docker compose' (sem hífen)
# Os passos de build e execução podem continuar...
# Certifique-se de que existe um arquivo docker-compose.yml no diretório atual

if [ -f "docker-compose.yml" ]; then
  echo "### Construindo a imagem Docker diretamente no Raspberry Pi com docker compose"
  docker compose build

  echo "-----------------------------------------------------------------------"
  echo "### Verificando se a imagem foi carregada ou criada corretamente"
  docker images

  echo "PASSO 3: Executando o container Docker"
  echo "--------------------------------------------"


  echo "### Criando uma rede para containers se verem pelo nome"
  if ! docker network ls --format '{{.Name}}' | grep -q '^web-net$'; then
    docker network create web-net
  else
    echo "### A rede 'web-net' já existe. Pulando a criação."
  fi

  echo "### Executando o container em modo daemon"
  #docker run -d --name nginx_proxy --privileged --network web-net -p 80:80 rpi-nginx:latest
  docker compose up -d

  echo "### Verificando se o container está em execução"
  docker ps

  echo "### Verificando os logs do container"
  docker logs -f nginx_proxy
  docker logs -f flask_app
else
    echo "### ### AVISO: Arquivo docker-compose.yml não encontrado. Pulando os passos de build e execução."
    exit 0
fi

cat << 'EOF'
======================================================================
PASSO 4: Gerenciar o container
------------------------------

Você pode gerenciar o container usando os seguintes comandos:

# Parar o container
docker stop flask_app
ou
docker compose stop webapp
ou 
docker compose stop

# Iniciar o container
docker start nginx_proxy
ou
docker compose start nginx
ou
docker compose start

# Reiniciar o container
docker restart nginx_prxy
ou
docker compose restart webapp
ou
docker compose restart

# Remover o container (precisa estar parado)
docker stop nginx_proxy
docker rm nginx_proxy
ou
docker compose down

# Executar o container com reinicialização automática
docker run -d --name nginx_proxy --privileged --restart unless-stopped -p 80:80 rpi-nginx:latest

PASSO 5: Configurar o container para iniciar automaticamente na inicialização
---------------------------------------------------------------------------
O parâmetro --restart unless-stopped já garante que o container seja reiniciado 
automaticamente quando o Docker for iniciado, mesmo após reinicialização do sistema.

PASSO 6: Verificar o status do firewall
-------------------------------------
# Verificar o status do Iptables dentro do container
iptables -L -n -v

# Se precisar ajustar regras do firewall no host Raspberry Pi:
sudo iptables -L -n -v                                  #Listar regras do firewall
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT    #Adicionar regra para aceitar conexões na porta 8080   ''
sudo iptables -A INPUT -j DROP                          #Bloquear todas as outras conexões            
sudo iptables -D INPUT -p tcp --dport 8080 -j ACCEPT    #Remover regra para aceitar conexões na porta 8080
sudo iptables-save > /etc/iptables.rules
EOF

echo ""
echo
echo "### Agora você poderá acessar o servidor web através do IP do Raspberry Pi."
