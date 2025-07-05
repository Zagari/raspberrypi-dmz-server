#!/bin/bash

# Script para configurar o firewall Iptables no host do Raspberry Pi
# Executar como root: sudo ./setup-iptables.sh

# Garante que o script pare se algum comando falhar
set -e

echo "================================================="
echo "  Configurando o Firewall Iptables no Host...  "
echo "================================================="

# Verifica se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
   echo "Este script precisa ser executado como root. Use 'sudo ./setup-iptables.sh'" >&2
   exit 1
fi

echo "[1/4] Instalando 'iptables-persistent' para salvar as regras..."
# Instala o pacote que permite que as regras do iptables sobrevivam a um reboot
# Durante a instalação, ele pode perguntar se deseja salvar as regras atuais IPv4/IPv6. Pode confirmar (Sim).
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

echo "[2/4] Limpando todas as regras existentes (Flush)..."
# Primeiro, permita tudo para não se trancar fora durante a execução do script
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
# Limpa todas as regras, chains e zera contadores
sudo iptables -F # Limpa todas as regras
sudo iptables -X # Apaga todas as chains não-padrão
sudo iptables -Z # Zera todos os contadores
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

echo "[3/4] Definindo as regras do firewall..."

# --- POLÍTICAS PADRÃO ---
# Bloqueia todo o tráfego de entrada e encaminhamento por padrão
iptables -P INPUT DROP
iptables -P FORWARD DROP
# Permite todo o tráfego de saída
iptables -P OUTPUT ACCEPT

# --- REGRAS DE ACEITAÇÃO (ALLOW) ---

# --- REGRAS PARA PROTEGER O HOST (Chain INPUT) ---
# Permite tráfego na interface de loopback (essencial para o sistema)
iptables -A INPUT -i lo -j ACCEPT

# Permite conexões já estabelecidas e relacionadas (muito importante!)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permite Ping (ICMP echo-request) para diagnóstico de rede
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Permite SSH (porta 22) para que você possa administrar o Pi
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# --- REGRAS PARA PROTEGER OS CONTAINERS DOCKER (Chain DOCKER-USER) ---
echo "--> Adicionando regras para os Containers Docker na chain DOCKER-USER..."
# Permite conexões estabelecidas retornarem aos containers
sudo iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Permite acesso externo à porta 80 (HTTP) dos containers
sudo iptables -A DOCKER-USER -p tcp --dport 80 -j ACCEPT
# Permite acesso externo à porta 443 (HTTPS) dos containers
sudo iptables -A DOCKER-USER -p tcp --dport 443 -j ACCEPT
# Permite acesso externo à porta 8000 dos containers
sudo iptables -A DOCKER-USER -p tcp --dport 8000 -j ACCEPT

# Se você precisar de outras portas, como a porta do Minecraft (25565), adicione aqui:
# iptables -A DOCKER-USER -p tcp --dport 25565 -j ACCEPT

echo "[4/4] Salvando as regras para persistirem após o reboot..."
# O iptables-persistent usa este comando para salvar as regras
# Cria o diretório se não existir
sudo mkdir -p /etc/iptables
# Salva as regras
iptables-save > /etc/iptables/rules.v4

echo ""
echo "================================================="
echo "          Configuração concluída!              "
echo "================================================="
echo "As seguintes regras estão ativas:"
echo ""
iptables -L -n -v
echo ""
echo "As regras foram salvas e serão recarregadas na próxima inicialização."

exit 0