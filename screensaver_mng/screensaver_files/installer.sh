#!/bin/bash
# Script de instalação para Screensaver no Raspberry Pi 2
# Debian/Raspbian

set -e

echo "=== Instalador do Screensaver ==="
echo "Configurando protetor de tela para Raspberry Pi 2"

# Verificar se está executando como root
if [[ $EUID -eq 0 ]]; then
   echo "Erro: Não execute este script como root"
   echo "Use: ./install.sh"
   exit 1
fi

# Diretório de instalação
INSTALL_DIR="$HOME/screensaver"
SERVICE_NAME="screensaver"

# Função para instalar dependências
install_dependencies() {
    echo "Instalando dependências..."
    
    # Atualizar repositórios
    sudo apt update
    
    # Instalar Python 3 e pip se não estiver instalado
    sudo apt install -y python3 python3-pip
    
    # Instalar pygame (versão otimizada para Raspberry Pi)
    echo "Instalando pygame..."
    sudo apt install -y python3-pygame
    
    # Instalar dependências do SDL para framebuffer
    sudo apt install -y libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
    
    # Instalar ferramentas adicionais
    sudo apt install -y git screen htop
    
    echo "Dependências instaladas com sucesso!"
}

# Função para criar estrutura de diretórios
setup_directories() {
    echo "Criando estrutura de diretórios..."
    
    # Criar diretório principal
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/scripts"
    
    echo "Diretórios criados!"
}

# Função para criar arquivo de configuração
create_config() {
    echo "Criando arquivo de configuração..."
    
    cat > "$INSTALL_DIR/config.py" << 'EOF'
# Configuração do Screensaver

# Configurações de display
SCREEN_WIDTH = 720
SCREEN_HEIGHT = 576
FPS = 20  # Reduzido para economizar CPU no RPi 2

# Configurações de efeitos
EFFECT_DURATION = 15000  # 15 segundos por efeito
FONT_SIZE = 72

# Configurações de energia
IDLE_TIMEOUT = 600  # 10 minutos até ativar screensaver
SLEEP_TIMEOUT = 1800  # 30 minutos até desligar display

# Configurações de input
ENABLE_MOUSE_DETECTION = True
ENABLE_KEYBOARD_DETECTION = True

# Configurações de log
LOG_LEVEL = "INFO"
LOG_FILE = "/home/pi/screensaver/logs/screensaver.log"

# Configurações avançadas
USE_FRAMEBUFFER = True  # Usar framebuffer direto quando possível
OPTIMIZE_FOR_RPI = True  # Otimizações específicas para Raspberry Pi
EOF

    echo "Arquivo de configuração criado!"
}

# Função para criar script de inicialização
create_startup_script() {
    echo "Criando script de inicialização..."
    
    cat > "$INSTALL_DIR/start_screensaver.sh" << EOF
#!/bin/bash
# Script de inicialização do Screensaver

# Configurar variáveis de ambiente
export DISPLAY=:0
export SDL_FBDEV=/dev/fb0
export SDL_VIDEODRIVER=fbcon
export SDL_NOMOUSE=1

# Aguardar sistema estar pronto
sleep 5

# Navegar para diretório do screensaver
cd "$INSTALL_DIR"

# Executar screensaver
python3 screensaver.py 2>&1 | tee -a logs/screensaver.log

EOF

    chmod +x "$INSTALL_DIR/start_screensaver.sh"
    echo "Script de inicialização criado!"
}

# Função para criar serviço systemd
create_systemd_service() {
    echo "Criando serviço systemd..."
    
    cat > "/tmp/$SERVICE_NAME.service" << EOF
[Unit]
Description=Screensaver
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/start_screensaver.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical-session.target
EOF

    # Instalar serviço
    sudo mv "/tmp/$SERVICE_NAME.service" "/etc/systemd/system/"
    sudo systemctl daemon-reload
    
    echo "Serviço systemd criado!"
}

# Função para configurar permissões
setup_permissions() {
    echo "Configurando permissões..."
    
    # Adicionar usuário ao grupo video para acessar framebuffer
    sudo usermod -a -G video $USER
    
    # Definir permissões para framebuffer
    sudo chmod 666 /dev/fb0 2>/dev/null || true
    
    # Criar regra udev para framebuffer
    echo 'SUBSYSTEM=="graphics", KERNEL=="fb*", MODE="0666"' | sudo tee /etc/udev/rules.d/99-framebuffer.rules
    
    echo "Permissões configuradas!"
}

# Função para otimizar sistema para RPi 2
optimize_system() {
    echo "Aplicando otimizações para Raspberry Pi 2..."
    
    # Configurar GPU memory split (mais memória para CPU)
    if ! grep -q "gpu_mem=" /boot/config.txt; then
        echo "gpu_mem=16" | sudo tee -a /boot/config.txt
    fi
    
    # Desabilitar serviços desnecessários
    sudo systemctl disable bluetooth.service 2>/dev/null || true
    sudo systemctl disable cups.service 2>/dev/null || true
    sudo systemctl disable avahi-daemon.service 2>/dev/null || true
    
    # Configurar swappiness (reduzir uso de swap)
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    
    echo "Otimizações aplicadas!"
}

# Função para testar instalação
test_installation() {
    echo "Testando instalação..."
    
    # Verificar se pygame está funcionando
    python3 -c "import pygame; print('pygame OK')" || {
        echo "Erro: pygame não está funcionando"
        exit 1
    }
    
    # Verificar se o script principal existe
    if [[ -f "$INSTALL_DIR/screensaver.py" ]]; then
        echo "Script principal encontrado!"
    else
        echo "Erro: Script principal não encontrado"
        exit 1
    fi
    
    echo "Teste concluído com sucesso!"
}

# Função principal
main() {
    echo "Iniciando instalação..."
    
    # Verificar se é Raspberry Pi
    if [[ ! -f /proc/cpuinfo ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        echo "Aviso: Este script foi otimizado para Raspberry Pi"
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Executar etapas de instalação
    install_dependencies
    setup_directories
    create_config
    create_startup_script
    create_systemd_service
    setup_permissions
    optimize_system
    
    # Copiar script principal para diretório de instalação
    if [[ -f "screensaver.py" ]]; then
        cp screensaver.py "$INSTALL_DIR/"
    else
        echo "Erro: screensaver.py não encontrado no diretório atual"
        echo "Certifique-se de que o arquivo está no mesmo diretório do instalador"
        exit 1
    fi
    
    test_installation
    
    echo ""
    echo "=== Instalação Concluída! ==="
    echo "Diretório de instalação: $INSTALL_DIR"
    echo ""
    echo "Para iniciar o screensaver:"
    echo "  cd $INSTALL_DIR && ./start_screensaver.sh"
    echo ""
    echo "Para ativar inicialização automática:"
    echo "  sudo systemctl enable $SERVICE_NAME"
    echo "  sudo systemctl start $SERVICE_NAME"
    echo ""
    echo "Para ver logs:"
    echo "  tail -f $INSTALL_DIR/logs/screensaver.log"
    echo ""
    echo "Controles:"
    echo "  ESC ou Q: Sair"
    echo "  SPACE: Trocar efeito"
    echo ""
    echo "Reinicie o sistema para aplicar todas as configurações!"
}

# Executar instalação
main "$@"