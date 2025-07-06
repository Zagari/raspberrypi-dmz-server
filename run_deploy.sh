#!/bin/bash

# Script para executar o container Docker no Raspberry Pi 2
echo "======================================================================"
echo "Gerando imagem do container Docker para o Raspberry Pi 2"
echo ""
docker buildx build --platform linux/arm/v7 -t <IMAGE_NAME>:latest . --output type=docker   

echo "Salvando a imagem como arquivo tar..."
echo ""
docker save <IMAGE_NAME>:latest > <IMAGE_NAME>.tar

echo "Copiando a imagem para o Raspberry Pi 2..."
echo ""
scp <IMAGE_NAME>.tar USER@IP_DO_RASPBERRY:~/dmz/

echo "Parando o container existente (se houver)..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker stop <CONTAINER_NAME> || true"

echo "Removendo o container existente (se houver)..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker rm <CONTAINER_NAME> || true"

echo "Removendo a imagem antiga (se houver)..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker rmi <IMAGE_NAME>:latest || true"

echo "Criando uma rede para containers se verem pelo nome..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker network create web-net || true"

echo "Carregando a imagem no Raspberry Pi 2..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker load < ~/dmz/<IMAGE_NAME>.tar"

echo "Iniciando o container Docker..."
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ "docker run -d --name <CONTAINER_NAME> || true" --privileged --network web-net -p 80:80 -p 443:443 <IMAGE_NAME>:latest"

echo ""
echo "======================================================================"
echo "Container Docker iniciado com sucesso!"
echo "Você pode verificar o status do container com:"
echo ""
echo "ssh USER@IP_DO_RASPBERRY:~/dmz/ 'docker ps'"
echo ""
echo "Para acessar o container e verificar os logs, use:"
echo ""
echo "ssh USER@IP_DO_RASPBERRY:~/dmz/ 'docker logs <CONTAINER_NAME> || true"'"
echo ""
echo "Para acessar o firewall, use:"
echo ""
echo "ssh USER@IP_DO_RASPBERRY:~/dmz/ 'docker exec <CONTAINER_NAME> || true"iptables -L -n -v'"
echo ""
echo "Para acessar o Nginx, use:"
echo ""
ssh USER@IP_DO_RASPBERRY:~/dmz/ 'docker exec <CONTAINER_NAME> || true"cat /var/log/nginx/error.log'
echo ""