import subprocess
from flask import Flask, render_template, jsonify, url_for
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)

# Configurações do Screensaver
TMUX_SESSION_NAME = "screensaver_session"
SCREENSAVER_DIR = "/home/zagari/screensaver"
SCREENSAVER_COMMAND = "python3 screensaver.py 2>&1 | tee -a logs/screensaver.log"
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
    try:
        subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        return True, ""
    except subprocess.CalledProcessError as e:
        return False, e.stderr

def is_session_running():
    result = subprocess.run(f"tmux has-session -t {TMUX_SESSION_NAME}", shell=True)
    return result.returncode == 0

# --- ROTAS PRINCIPAIS DA APLICAÇÃO ---

@app.route('/')
# def homepage():
    # """Serve a página principal com os cards."""
    # return render_template('homepage.html')

# @app.route('/screensaver')
def screensaver_page():
    """Serve a página de gerenciamento do screensaver."""
    return render_template('screensaver.html')

app.wsgi_app = ProxyFix(
    app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1
)

# --- ROTAS DA API DO SCREENSAVER ---

@app.route('/screensaver/status')
def screensaver_status():
    """Verifica e retorna o status do screensaver."""
    if is_session_running():
        return jsonify({"status": "running"})
    else:
        return jsonify({"status": "stopped"})

@app.route('/screensaver/start', methods=['POST'])
def start_screensaver():
    if is_session_running():
        return jsonify({"status": "error", "message": "Screensaver já está rodando."}), 409
    
    run_command(f"tmux new-session -d -s {TMUX_SESSION_NAME}")
    run_command(f"tmux send-keys -t {TMUX_SESSION_NAME} '{FULL_COMMAND}' C-m")
    
    return jsonify({"status": "success", "message": "Comando para iniciar o screensaver enviado."})

@app.route('/screensaver/stop', methods=['POST'])
def stop_screensaver():
    if not is_session_running():
        return jsonify({"status": "error", "message": "Screensaver não está rodando."}), 404
        
    run_command(f"tmux kill-session -t {TMUX_SESSION_NAME}")
    return jsonify({"status": "success", "message": "Screensaver encerrado."})

@app.route('/screensaver/change', methods=['POST'])
def change_effect():
    if not is_session_running():
        return jsonify({"status": "error", "message": "Screensaver não está rodando."}), 404
        
    run_command(f"tmux send-keys -t {TMUX_SESSION_NAME}:0.0 ' '")
    return jsonify({"status": "success", "message": "Comando para mudar o efeito enviado."})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)