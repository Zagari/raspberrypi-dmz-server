import subprocess
from flask import Flask, render_template, jsonify

app = Flask(__name__)

# Configurações
TMUX_SESSION_NAME = "screensaver_session"
SCREENSAVER_DIR = "/home/zagari/screensaver"
SCREENSAVER_COMMAND = "python3 screensaver.py 2>&1 | tee -a logs/screensaver.log"
# String completa com os exports para garantir que o ambiente esteja correto
FULL_COMMAND = (
    f"export DISPLAY=:0; "
    f"export SDL_FBDEV=/dev/fb0; "
    f"export SDL_VIDEODRIVER=fbcon; "
    f"export SDL_NOMOUSE=1; "
    f"sleep 5; "
    f"cd {SCREENSAVER_DIR}; "
    f"{SCREENSAVER_COMMAND}"
)

def run_command(command):
    """Função auxiliar para executar comandos no shell."""
    try:
        # Usamos shell=True por causa dos pipes e redirecionamentos no comando completo
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return {"success": True, "output": result.stdout}
    except subprocess.CalledProcessError as e:
        return {"success": False, "error": e.stderr}

def is_session_running():
    """Verifica se a sessão tmux está ativa."""
    # O comando `tmux has-session` retorna 0 se a sessão existe, e 1 se não existe.
    result = subprocess.run(f"tmux has-session -t {TMUX_SESSION_NAME}", shell=True)
    return result.returncode == 0

@app.route('/')
def index():
    """Serve a página principal."""
    return render_template('index.html')

@app.route('/status')
def status():
    """Verifica e retorna o status do screensaver."""
    if is_session_running():
        return jsonify({"status": "running"})
    else:
        return jsonify({"status": "stopped"})

@app.route('/start', methods=['POST'])
def start_screensaver():
    """Inicia o screensaver em uma nova sessão tmux."""
    if is_session_running():
        return jsonify({"status": "error", "message": "Screensaver já está rodando."}), 409

    # 1. Cria a sessão tmux em background (-d)
    run_command(f"tmux new-session -d -s {TMUX_SESSION_NAME}")
    
    # 2. Envia o comando completo para ser executado na sessão
    #    'C-m' é o equivalente a pressionar Enter.
    run_command(f"tmux send-keys -t {TMUX_SESSION_NAME} '{FULL_COMMAND}' C-m")
    
    return jsonify({"status": "success", "message": "Comando para iniciar o screensaver enviado."})

@app.route('/stop', methods=['POST'])
def stop_screensaver():
    """Para o screensaver enviando 'q' ou matando a sessão."""
    if not is_session_running():
        return jsonify({"status": "error", "message": "Screensaver não está rodando."}), 404

    # A maneira mais garantida de parar é matar a sessão tmux.
    # Enviar 'q' pode não funcionar se o programa travar.
    run_command(f"tmux kill-session -t {TMUX_SESSION_NAME}")
    
    return jsonify({"status": "success", "message": "Comando para parar o screensaver enviado."})

@app.route('/change', methods=['POST'])
def change_effect():
    """Muda o efeito enviando a tecla de espaço."""
    if not is_session_running():
        return jsonify({"status": "error", "message": "Screensaver não está rodando para mudar o efeito."}), 404
        
    # Envia a tecla de espaço (' ') para o terminal.
    # A sintaxe -t {sessao}:0.0 é mais específica, visando o primeiro painel da primeira janela.
    run_command(f"tmux send-keys -t {TMUX_SESSION_NAME}:0.0 ' '")
    
    return jsonify({"status": "success", "message": "Comando para mudar o efeito enviado."})


if __name__ == '__main__':
    # Use host='0.0.0.0' para tornar o servidor acessível na sua rede local.
    app.run(host='0.0.0.0', port=5000, debug=True)

