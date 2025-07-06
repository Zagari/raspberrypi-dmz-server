#!/bin/bash

# Script para validar o funcionamento da imagem e do container no Raspberry Pi 2
pause_for_user() {
   echo "Pressione [ENTER] para continuar ou [ESC] para interromper..."
   while true; do
       IFS= read -rsn1 key
       if [[ $key == "" ]]; then
            break
       elif [[ $key == $'\e' ]]; then
            echo "Interrompido pelo usuário."
            exit 1
       fi
   done
   echo ""
}

echo "Validando o funcionamento da imagem e do container no Raspberry Pi 2"
echo "=============================================================================="
echo ""
echo "Este script executa algumas instruções para você validar se tudo está funcionando corretamente."
echo ""

echo "PASSO 1: Verificar se o container está em execução"
echo "--------------------------------------------------"
echo "### Verificar o status do container"
docker ps

pause_for_user

echo "### Se o container não estiver listado, verifique todos os containers (incluindo os parados)"
docker ps -a

pause_for_user

echo "### Se o container estiver parado, inicie-o"
cat << 'EOF'
docker start nginx_proxy
ou
docker start webapp
EOF
pause_for_user

echo "PASSO 2: Verificar os logs do container"
echo "---------------------------------------"
echo "### Visualizar os logs do container nginx_proxy"
docker logs nginx_proxy
echo "### Visualizar os logs do container webapp (se aplicável)"
docker logs webapp
pause_for_user
echo "### Acompanhar os logs em tempo real"
cat << 'EOF'
# Acompanhar os logs do container nginx_proxy em tempo real
docker logs -f nginx_proxy
# Acompanhar os logs do container webapp em tempo real (se aplicável)
docker logs -f webapp
EOF
pause_for_user

echo "PASSO 3: Verificar o status do firewall"
echo "---------------------------------------"
echo "### Verificar o status do firewall"
sudo iptables -L -n
pause_for_user

echo "### Listar as regras de firewall ativas"
sudo iptables -L -n -v

echo "PASSO 4: Testar o acesso ao servidor web"
echo "----------------------------------------"

echo "### Verifique se há erros nos logs do Nginx dentro do container"
docker exec nginx_proxy cat /var/log/nginx/error.log
pause_for_user

echo "### No Raspberry Pi, teste o acesso local"
curl http://localhost
pause_for_user

cat << 'EOF'
# Em outro dispositivo na mesma rede, abra um navegador e acesse:
http://IP_DO_RASPBERRY

# Verifique se a página web é carregada corretamente e se o uptime é exibido
EOF
pause_for_user

echo "PASSO 5: Verificar o uso de recursos"
echo "------------------------------------"
echo "### Verificar o uso de CPU e memória do container"
docker stats nginx_proxy --no-stream
pause_for_user

echo "### Verificar o uso de disco dentro do container"
docker exec nginx_proxy df -h
pause_for_user

cat << 'EOF'
PASSO 6: Testar a persistência após reinicialização
---------------------------------------------------
### Reiniciar o Raspberry Pi para verificar a persistência do container
sudo reboot

### Após a reinicialização, verificar se o container iniciou automaticamente
docker ps

### Se não iniciou automaticamente, verifique se o Docker está em execução
sudo systemctl status docker

### Inicie o container com a flag de reinicialização automática
docker run -d --name nginx_proxy --privileged --restart unless-stopped --network web-net -p 80:80 raspberrypi-dmz-server-nginx:latest
EOF
pause_for_user

cat << 'EOF'
PASSO 7: Solução de problemas comuns
----------------------------------
1. Se o container não iniciar:
   - Verifique os logs: docker logs nginx_proxy
   - Verifique se há conflitos de porta: netstat -tuln | grep 80
   - Verifique se há espaço em disco suficiente: df -h

#2. Se o servidor web não estiver acessível:
#   - Verifique se o Nginx está em execução: docker exec nginx-server service nginx status
#   - Verifique as configurações de rede: docker exec nginx-server ifconfig
#   - Teste o acesso local dentro do container: docker exec -it nginx-server curl localhost

3. Se o firewall estiver bloqueando conexões:
   - Verifique as regras do Iptables: docker exec nginx_proxy iptables -L -n -v || echo "iptables não está disponível ou falhou"
   - Ajuste as regras se necessário: docker exec nginx_proxy iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
EOF

echo ""
echo "Se tudo estiver funcionando corretamente, você terá um servidor web com firewall rodando em um container Docker no seu Raspberry Pi 2."
