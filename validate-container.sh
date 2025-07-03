#!/bin/bash

# Script para validar o funcionamento da imagem e do container no Raspberry Pi 2
echo "Instruções para validar o funcionamento da imagem e do container no Raspberry Pi 2"
echo "=============================================================================="
echo ""
echo "Este script contém instruções para validar se tudo está funcionando corretamente."
echo ""

cat << 'EOF'
PASSO 1: Verificar se o container está em execução
-------------------------------------------------
# Verificar o status do container
docker ps

# Se o container não estiver listado, verifique todos os containers (incluindo os parados)
docker ps -a

# Se o container estiver parado, inicie-o
docker start firewall-server

PASSO 2: Verificar os logs do container
-------------------------------------
# Visualizar os logs do container
docker logs firewall-server

# Acompanhar os logs em tempo real
docker logs -f firewall-server

PASSO 3: Verificar o status do firewall
-------------------------------------
# Verificar o status do UFW dentro do container
docker exec firewall-server iptables -L -n

# Verificar as regras de firewall ativas
docker exec firewall-server iptables -L -n -v


PASSO 4: APENAS se tiver colocado um servidor nginx/web na imagem, testar o acesso ao servidor web
--------------------------------------
# Se tiver colocado um Ngnix na imagem, verifique se há erros nos logs do Nginx dentro do container
docker exec firewall-server cat /var/log/nginx/error.log

# No Raspberry Pi, teste o acesso local
curl http://localhost

# Em outro dispositivo na mesma rede, abra um navegador e acesse:
http://IP_DO_RASPBERRY

# Verifique se a página web é carregada corretamente e se o uptime é exibido

# Testar o endpoint de uptime (por exemplo, um endpoint CGI que retorna o uptime do sistema)
# curl http://IP_DO_RASPBERRY/uptime

# Deve retornar o uptime do sistema no formato "up X days, Y hours, Z minutes"

PASSO 5: Verificar o uso de recursos
----------------------------------
# Verificar o uso de CPU e memória do container
docker stats firewall-server --no-stream

# Verificar o uso de disco
docker exec firewall-server df -h

PASSO 6: Testar a persistência após reinicialização
-------------------------------------------------
# Reiniciar o Raspberry Pi
sudo reboot

# Após a reinicialização, verificar se o container iniciou automaticamente
docker ps

# Se não iniciou automaticamente, verifique se o Docker está em execução
sudo systemctl status docker

# Inicie o container com a flag de reinicialização automática
docker run -d --name firewall-server --privileged --restart unless-stopped --network web-net -p 80:80 rpi-ubuntu-iptables:latest

PASSO 7: Solução de problemas comuns
----------------------------------
1. Se o container não iniciar:
   - Verifique os logs: docker logs firewall-server
   - Verifique se há conflitos de porta: netstat -tuln | grep 80
   - Verifique se há espaço em disco suficiente: df -h

#2. Se o servidor web não estiver acessível:
#   - Verifique se o Nginx está em execução: docker exec nginx-server service nginx status
#   - Verifique as configurações de rede: docker exec nginx-server ifconfig
#   - Teste o acesso local dentro do container: docker exec -it nginx-server curl localhost

3. Se o firewall estiver bloqueando conexões:
   - Verifique as regras do Iptables: docker exec firewall-server iptables -L -n -v || echo "iptables não está disponível ou falhou"
   - Ajuste as regras se necessário: docker exec firewall-server iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

#4. Se o CGI não funcionar:
#   - Verifique se o fcgiwrap está em execução: docker exec nginx-server service fcgiwrap status
#   - Verifique as permissões do script: docker exec nginx-server ls -la /usr/lib/cgi-bin/uptime.sh
EOF

echo ""
echo "Siga estas instruções para validar o funcionamento do container no Raspberry Pi 2."
echo "Se tudo estiver funcionando corretamente, você terá um servidor web com firewall rodando em um container Docker no seu Raspberry Pi 2."
