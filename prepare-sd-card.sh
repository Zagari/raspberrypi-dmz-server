#!/bin/bash

# Script para preparar o cartão de memória para o Raspberry Pi 2
echo "Instruções para preparar o cartão de memória para o Raspberry Pi 2"
echo "================================================================"
echo ""
echo "Este script contém apenas instruções. Você precisará executar os comandos manualmente."
echo ""

cat << 'EOF'
PASSO 1: Baixar o Raspberry Pi OS Lite (32-bit)
-----------------------------------------------
O Raspberry Pi 2 utiliza arquitetura ARMv7, então precisamos do Raspberry Pi OS de 32 bits.

Acesse: https://www.raspberrypi.com/software/operating-systems/
Baixe: "Raspberry Pi OS Lite (Legacy)" - versão de 32 bits sem desktop

PASSO 2: Instalar o Raspberry Pi Imager
---------------------------------------
No Linux:
sudo apt-get update
sudo apt-get install rpi-imager

No macOS:
brew install raspberry-pi-imager

No Windows:
Baixe e instale de: https://www.raspberrypi.com/software/

PASSO 3: Gravar a imagem no cartão SD
-------------------------------------
1. Insira o cartão SD no computador
2. Abra o Raspberry Pi Imager
3. Clique em "ESCOLHER OS"
4. Selecione "Usar imagem personalizada" e navegue até o arquivo .img baixado
5. Clique em "ESCOLHER ARMAZENAMENTO" e selecione o cartão SD
6. Clique em "CONFIGURAÇÕES" (ícone de engrenagem)
   - Ative "Habilitar SSH"
   - Defina nome de usuário e senha
   - Configure sua rede Wi-Fi (opcional)
7. Clique em "GRAVAR" e aguarde a conclusão

PASSO 4: Configuração inicial (opcional)
---------------------------------------
Após gravar a imagem, você pode precisar editar alguns arquivos na partição boot do cartão SD:

No Windows:
Após a gravação ser concluída, remova e reinsira o cartão SD no computador
O Windows deve reconhecer automaticamente a partição boot e atribuir uma letra de unidade (por exemplo, E: ou F:)
Abra o Explorador de Arquivos e navegue até essa unidade
Você verá vários arquivos, incluindo config.txt e cmdline.txt - esta é a partição boot

No macOS:
Após a gravação, remova e reinsira o cartão SD
O macOS deve montar automaticamente a partição boot como "boot"
Abra o Finder e procure por "boot" na barra lateral ou em Dispositivos
Clique nela para acessar os arquivos da partição boot

No Linux:
Após a gravação, remova e reinsira o cartão SD
Em muitas distribuições Linux, a partição boot será montada automaticamente
Você pode encontrá-la em /media/$USER/boot ou /mnt/boot
Se não for montada automaticamente, use estes comandos:
# Identifique o dispositivo do cartão SD
lsblk

# Monte a partição boot (substitua sdX1 pelo dispositivo correto)
sudo mkdir -p /media/$USER/boot
sudo mount /dev/sdX1 /media/$USER/boot
Acesse a partição com:
cd /media/$USER/boot

Depois de acessar a partição boot, crie os arquivos necessários conforme as instruções abaixo:

1. Para configurar Wi-Fi, crie um arquivo chamado 'wpa_supplicant.conf':
cat > /media/$USER/boot/wpa_supplicant.conf << 'WPAEOF'
country=BR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="SUA_REDE_WIFI"
    psk="SUA_SENHA_WIFI"
    key_mgmt=WPA-PSK
}
WPAEOF

2. Para habilitar SSH, crie um arquivo vazio chamado 'ssh':
touch /media/$USER/boot/ssh

PASSO 5: Ejetar o cartão SD com segurança
----------------------------------------
Ejete o cartão SD do computador e insira-o no Raspberry Pi 2.

PASSO 6: Iniciar o Raspberry Pi 2
--------------------------------
1. Conecte o Raspberry Pi 2 à energia
2. Conecte um cabo de rede (se não estiver usando Wi-Fi)
3. Aguarde cerca de 1 minuto para o sistema inicializar

PASSO 7: Encontrar o IP do Raspberry Pi
--------------------------------------
Use um dos métodos abaixo:
- Verifique no seu roteador os dispositivos conectados
- Use um scanner de rede como: nmap -sn 192.168.1.0/24
- Conecte um monitor e teclado ao Raspberry Pi e execute 'ip addr'

PASSO 8: Conectar via SSH
-----------------------
ssh pi@IP_DO_RASPBERRY
(ou o nome de usuário que você configurou)

EOF

echo ""
echo "Siga estas instruções para preparar o cartão SD para o Raspberry Pi 2."
echo "Depois de inicializar o sistema, você poderá instalar o Docker e executar o container."
