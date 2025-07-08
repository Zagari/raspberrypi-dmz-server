#!/bin/bash
# Script de controle do Screensaver
# Facilita o gerenciamento do screensaver

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/screensaver"
SERVICE_NAME="screensaver"
CONFIG_FILE="$INSTALL_DIR/config.py"
LOG_FILE="$INSTALL_DIR/logs/screensaver.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Função para verificar se o serviço existe
check_service() {
    if systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
        return 0
    else
        return 1
    fi
}

# Função para verificar status do serviço
get_service_status() {
    if check_service; then
        systemctl is-active "$SERVICE_NAME" 2>/dev/null
    else
        echo "não instalado"
    fi
}

# Função para mostrar informações do sistema
show_system_info() {
    print_header "Informações do Sistema"
    
    echo "Modelo: $(cat /proc/device-tree/model 2>/dev/null || echo 'Não identificado')"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Não identificado')"
    echo "Temperatura CPU: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
    echo "Memória GPU: $(vcgencmd get_mem gpu 2>/dev/null || echo 'N/A')"
    echo "Resolução atual: $(fbset -s 2>/dev/null | grep 'mode' | head -1 || echo 'N/A')"
    echo "Python: $(python3 --version 2>/dev/null || echo 'Não instalado')"
    echo "pygame: $(python3 -c 'import pygame; print(pygame.version.ver)' 2>/dev/null || echo 'Não instalado')"
    echo ""
}

# Função para mostrar status do screensaver
show_status() {
    print_header "Status do Zagari Screensaver"
    
    local status=$(get_service_status)
    echo "Status do serviço: $status"
    
    if [[ "$status" == "active" ]]; then
        echo -e "Estado: ${GREEN}Rodando${NC}"
    elif [[ "$status" == "inactive" ]]; then
        echo -e "Estado: ${YELLOW}Parado${NC}"
    elif [[ "$status" == "failed" ]]; then
        echo -e "Estado: ${RED}Falhou${NC}"
    else
        echo -e "Estado: ${RED}Não instalado${NC}"
    fi
    
    if check_service; then
        echo "Habilitado para inicialização: $(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null)"
        echo "Última inicialização: $(systemctl show "$SERVICE_NAME" -p ActiveEnterTimestamp --value 2>/dev/null || echo 'N/A')"
    fi
    
    # Verificar se processo está rodando
    if pgrep -f "zagari_screensaver.py" > /dev/null; then
        local pid=$(pgrep -f "zagari_screensaver.py")
        echo "PID do processo: $pid"
        echo "Uso de memória: $(ps -p $pid -o rss= 2>/dev/null | awk '{print $1/1024 " MB"}' || echo 'N/A')"
        echo "Uso de CPU: $(ps -p $pid -o pcpu= 2>/dev/null | awk '{print $1"%"}' || echo 'N/A')"
    fi
    
    echo ""
}

# Função para iniciar o screensaver
start_screensaver() {
    print_header "Iniciando Zagari Screensaver"
    
    if [[ "$(get_service_status)" == "active" ]]; then
        print_warning "Screensaver já está rodando"
        return 0
    fi
    
    if check_service; then
        print_status "Iniciando serviço systemd..."
        sudo systemctl start "$SERVICE_NAME"
        sleep 2
        
        if [[ "$(get_service_status)" == "active" ]]; then
            print_status "Screensaver iniciado com sucesso!"
        else
            print_error "Falha ao iniciar screensaver"
            return 1
        fi
    else
        print_status "Iniciando manualmente..."
        cd "$INSTALL_DIR"
        nohup python3 zagari_screensaver.py > "$LOG_FILE" 2>&1 &
        sleep 2
        
        if pgrep -f "zagari_screensaver.py" > /dev/null; then
            print_status "Screensaver iniciado manualmente!"
        else
            print_error "Falha ao iniciar screensaver"
            return 1
        fi
    fi
}

# Função para parar o screensaver
stop_screensaver() {
    print_header "Parando Zagari Screensaver"
    
    if check_service && [[ "$(get_service_status)" == "active" ]]; then
        print_status "Parando serviço systemd..."
        sudo systemctl stop "$SERVICE_NAME"
        print_status "Serviço parado!"
    fi
    
    # Matar processo se ainda estiver rodando
    if pgrep -f "zagari_screensaver.py" > /dev/null; then
        print_status "Encerrando processo..."
        pkill -f "zagari_screensaver.py"
        sleep 1
        
        if ! pgrep -f "zagari_screensaver.py" > /dev/null; then
            print_status "Processo encerrado!"
        else
            print_warning "Forçando encerramento..."
            pkill -9 -f "zagari_screensaver.py"
        fi
    fi
}

# Função para reiniciar o screensaver
restart_screensaver() {
    print_header "Reiniciando Zagari Screensaver"
    
    stop_screensaver
    sleep 2
    start_screensaver
}

# Função para habilitar inicialização automática
enable_autostart() {
    print_header "Habilitando Inicialização Automática"
    
    if check_service; then
        sudo systemctl enable "$SERVICE_NAME"
        print_status "Inicialização automática habilitada!"
    else
        print_error "Serviço não encontrado. Execute a instalação primeiro."
        return 1
    fi
}

# Função para desabilitar inicialização automática
disable_autostart() {
    print_header "Desabilitando Inicialização Automática"
    
    if check_service; then
        sudo systemctl disable "$SERVICE_NAME"
        print_status "Inicialização automática desabilitada!"
    else
        print_warning "Serviço não encontrado."
    fi
}

# Função para mostrar logs
show_logs() {
    print_header "Logs do Zagari Screensaver"
    
    if [[ -f "$LOG_FILE" ]]; then
        echo "Logs do arquivo ($LOG_FILE):"
        echo "----------------------------------------"
        tail -n 20 "$LOG_FILE"
        echo "----------------------------------------"
        echo ""
    fi
    
    if check_service; then
        echo "Logs do systemd:"
        echo "----------------------------------------"
        journalctl -u "$SERVICE_NAME" --no-pager -n 20
        echo "----------------------------------------"
    fi
}

# Função para seguir logs em tempo real
follow_logs() {
    print_header "Acompanhando Logs em Tempo Real"
    print_status "Pressione Ctrl+C para parar"
    
    if check_service; then
        journalctl -u "$SERVICE_NAME" -f
    else
        if [[ -f "$LOG_FILE" ]]; then
            tail -f "$LOG_FILE"
        else
            print_error "Nenhum log encontrado"
        fi
    fi
}

# Função para editar configuração
edit_config() {
    print_header "Editando Configuração"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        if command -v nano > /dev/null; then
            nano "$CONFIG_FILE"
        elif command -v vim > /dev/null; then
            vim "$CONFIG_FILE"
        else
            print_error "Editor não encontrado. Edite manualmente: $CONFIG_FILE"
            return 1
        fi
        
        print_status "Configuração editada. Reinicie o screensaver para aplicar."
    else
        print_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
        return 1
    fi
}

# Função para teste rápido
test_screensaver() {
    print_header "Teste Rápido do Screensaver"
    
    if [[ ! -f "$INSTALL_DIR/zagari_screensaver.py" ]]; then
        print_error "Screensaver não encontrado em $INSTALL_DIR"
        return 1
    fi
    
    print_status "Testando dependências..."
    
    # Testar pygame
    if ! python3 -c "import pygame" 2>/dev/null; then
        print_error "pygame não instalado ou não funcionando"
        return 1
    fi
    
    # Testar framebuffer
    if [[ ! -w /dev/fb0 ]]; then
        print_warning "Sem acesso de escrita ao framebuffer /dev/fb0"
    fi
    
    print_status "Executando teste de 10 segundos..."
    cd "$INSTALL_DIR"
    timeout 10 python3 zagari_screensaver.py || print_warning "Teste interrompido"
    
    print_status "Teste concluído!"
}

# Função para mostrar ajuda
show_help() {
    echo "Zagari Screensaver - Script de Controle"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  status      - Mostra status do screensaver"
    echo "  info        - Mostra informações do sistema"
    echo "  start       - Inicia o screensaver"
    echo "  stop        - Para o screensaver"
    echo "  restart     - Reinicia o screensaver"
    echo "  enable      - Habilita inicialização automática"
    echo "  disable     - Desabilita inicialização automática"
    echo "  logs        - Mostra logs recentes"
    echo "  follow      - Acompanha logs em tempo real"
    echo "  config      - Edita arquivo de configuração"
    echo "  test        - Executa teste rápido"
    echo "  help        - Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 status   # Verificar status"
    echo "  $0 start    # Iniciar screensaver"
    echo "  $0 logs     # Ver logs"
    echo ""
}

# Função principal
main() {
    local command="${1:-status}"
    
    case "$command" in
        "status")
            show_status
            ;;
        "info")
            show_system_info
            ;;
        "start")
            start_screensaver
            ;;
        "stop")
            stop_screensaver
            ;;
        "restart")
            restart_screensaver
            ;;
        "enable")
            enable_autostart
            ;;
        "disable")
            disable_autostart
            ;;
        "logs")
            show_logs
            ;;
        "follow")
            follow_logs
            ;;
        "config")
            edit_config
            ;;
        "test")
            test_screensaver
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Comando desconhecido: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"