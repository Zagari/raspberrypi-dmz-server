# minecraft_mng/app.py
import os
import subprocess
import threading
import re
from flask import Flask, render_template, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix

# --- CONFIGURAÇÃO E ESTADO INICIAL ---
app = Flask(__name__)
app.config['SECRET_KEY'] = 'uma-chave-secreta-muito-forte!'

#  APLIQUE O MIDDLEWARE NA SUA APLICAÇÃO
# Ele vai ler os cabeçalhos X-Forwarded-* enviados pelo Nginx
# x_prefix=1 diz para ele confiar no cabeçalho X-Forwarded-Prefix vindo de 1 proxy.
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

# Caminhos para os scripts (dentro do contêiner)
TERRAFORM_DIR = '/app/terraform'
ANSIBLE_DIR = '/app/ansible'
ANSIBLE_INVENTORY = os.path.join(ANSIBLE_DIR, 'inventory.ini')
ANSIBLE_INVENTORY_TEMPLATE = os.path.join(ANSIBLE_DIR, 'inventory.ini.example')
ANSIBLE_VAULT_PASS = os.environ.get('ANSIBLE_VAULT_PASSWORD')

def sanitize_terminal_output(text: str) -> str:
    """
    Remove códigos de escape ANSI e caracteres de desenho de caixa de uma string.
    """
    # Expressão regular para encontrar códigos de escape ANSI
    ansi_escape_pattern = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    sanitized_text = ansi_escape_pattern.sub('', text)
    
    # Remove caracteres de desenho de caixa específicos do Terraform
    # (Você pode adicionar outros caracteres a esta string se necessário)
    box_chars = "╷│╵└├┌┐"
    for char in box_chars:
        sanitized_text = sanitized_text.replace(char, '')
        
    return sanitized_text.strip()


# Gerenciador de estado simples para saber o que está acontecendo
# Em uma aplicação maior, usaríamos Redis ou um banco de dados
status = {
    "current_process": "idle",  # pode ser 'idle', 'starting', 'stopping', 'running', 'error'
    "message": "Pronto para iniciar.",
    "public_ip": None,
    "last_log": []
}

# Lock para evitar condições de corrida ao modificar o estado
status_lock = threading.Lock()

# --- FUNÇÕES DE BACKGROUND (EXECUTAM TAREFAS PESADAS) ---

def run_command(command, cwd):
    """Executa um comando no shell e captura o output."""
    log_line = f"Executando: {' '.join(command)} em {cwd}"
    print(log_line)
    with status_lock:
        status['last_log'].append(log_line)
    
    process = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    # Captura logs em tempo real
    for line in iter(process.stdout.readline, ''):
        print(line.strip())
        with status_lock:
            status['last_log'].append(line.strip())

    process.wait()
    stderr_output = process.stderr.read()
    if process.returncode != 0:
        error_message = f"Erro ao executar comando: {stderr_output}"
        print(error_message)
        with status_lock:
            status['last_log'].append(error_message)
        raise Exception(error_message)
    
    return True

def run_ansible_command(command, cwd, vault_password):
    # Crie uma cópia do ambiente atual para não poluir o processo principal
    env = os.environ.copy()
    
    # A MUDANÇA CRÍTICA ESTÁ AQUI:
    env['ANSIBLE_CONFIG'] = os.path.join(ANSIBLE_DIR, '/ansible.cfg')
    
    """Executa um comando ansible-playbook, passando a senha do Vault via stdin."""
    log_line = f"Executando Ansible: {' '.join(command)} em {cwd}"
    print(log_line)
    with status_lock:
        status['last_log'].append(log_line)

    # Inicia o processo com stdin configurado como um 'pipe' para que possamos escrever nele
    process = subprocess.Popen(
        command,
        env=env, # Passa o ambiente modificado para o subprocesso
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE,  # <-- A MUDANÇA CRUCIAL
        text=True
    )

    # Envia a senha para o stdin do processo e captura a saída
    # O método .communicate() lida com o envio, leitura e espera pelo fim do processo.
    stdout_output, stderr_output = process.communicate(input=vault_password)

    # Exibe a saída nos logs do container para depuração
    if stdout_output:
        print(stdout_output)
        with status_lock:
            status['last_log'].extend(stdout_output.splitlines())
    if stderr_output:
        print(stderr_output)
        with status_lock:
            status['last_log'].extend(stderr_output.splitlines())

    # Verifica o código de retorno
    if process.returncode != 0:
        error_message = f"Erro ao executar comando Ansible: {stderr_output}"
        raise Exception(error_message)
    
    return True

def update_inventory(ip_address):
    """Atualiza o IP no arquivo de inventário do Ansible."""
    with open(ANSIBLE_INVENTORY_TEMPLATE, 'r') as f:
        template_content = f.read()
    
    # Substitui o placeholder pelo IP real
    content = re.sub(r'seu_ip_publico_aqui', ip_address, template_content)
    
    with open(ANSIBLE_INVENTORY, 'w') as f:
        f.write(content)
    print(f"Inventário Ansible '{ANSIBLE_INVENTORY}' atualizado com o IP: {ip_address}")


def start_minecraft_process():
    """Thread para iniciar a infra e o servidor Minecraft."""
    try:
        # 1. Aplicar Terraform
        with status_lock:
            status['current_process'] = 'starting'
            status['message'] = 'Iniciando infraestrutura com Terraform...'
            status['last_log'] = []
        # ==> PASSO 1.1: EXECUTAR 'INIT' PRIMEIRO E SEMPRE
        # Garante que os plugins e o backend S3 estejam prontos.
        run_command(['terraform', 'init', '-reconfigure'], TERRAFORM_DIR)

        # PASSO 1.2: Aplicar Terraform
        with status_lock:
            status['message'] = 'Criando infraestrutura com Terraform...'
        run_command(['terraform', 'apply', '-auto-approve'], TERRAFORM_DIR)

        # 2. Obter IP público do output do Terraform
        with status_lock:
            status['message'] = 'Obtendo IP público...'
        result = subprocess.run(['terraform', 'output', '-raw', 'public_ip'], cwd=TERRAFORM_DIR, capture_output=True, text=True)
        public_ip = result.stdout.strip()
        
        if not public_ip:
            raise Exception("Não foi possível obter o IP público do Terraform.")
        
        with status_lock:
            status['public_ip'] = public_ip
            status['message'] = f'IP {public_ip} obtido. Atualizando inventário Ansible.'
        
        # 3. Atualizar inventário Ansible
        update_inventory(public_ip)
        
        # 4. Executar playbooks Ansible
        ansible_base_cmd = ['ansible-playbook', '-i', ANSIBLE_INVENTORY]
        # Adicionamos --vault-password-file /dev/stdin APENAS para os playbooks que precisam
        ansible_vault_cmd_base = ansible_base_cmd + ['--vault-password-file', '/dev/stdin']
        
        with status_lock:
            status['message'] = 'Executando playbook do Cloudflare...'
        run_ansible_command(ansible_vault_cmd_base + ['deploy_updt_cloudflare.yml'], ANSIBLE_DIR, ANSIBLE_VAULT_PASS)
        
        with status_lock:
            status['message'] = 'Executando playbook do Minecraft...'
        run_command(ansible_base_cmd + ['deploy_minecraft.yml'], ANSIBLE_DIR)

        # Sucesso!
        with status_lock:
            status['current_process'] = 'running'
            status['message'] = f'Servidor Minecraft está rodando no IP: {public_ip}'

    except Exception as e:
        raw_error_message = str(e)
        sanitized_message = sanitize_terminal_output(raw_error_message)
        with status_lock:
            status['current_process'] = 'error'
            status['message'] = f"{sanitized_message}"
        print(f"Ocorreu um erro: {raw_error_message}")


def stop_minecraft_process():
    """Thread para fazer backup e destruir a infra."""
    try:
        with status_lock:
            status['current_process'] = 'stopping'
            status['message'] = 'Fazendo backup do mundo Minecraft...'
            status['last_log'] = []

        # 1. Executar playbook de backup
        ansible_vault_cmd_base = ['ansible-playbook', '-i', ANSIBLE_INVENTORY, '--vault-password-file', '/dev/stdin']
        
        with status_lock:
            status['current_process'] = 'stopping'
            status['message'] = 'Fazendo backup do mundo Minecraft...'
            status['last_log'] = []
        # ==> USA A NOVA FUNÇÃO AQUI <==
        run_ansible_command(ansible_vault_cmd_base + ['backup_minecraft.yml'], ANSIBLE_DIR, ANSIBLE_VAULT_PASS)

        # 2. Destruir infra com Terraform
        # ==> GARANTIR QUE O TERRAFORM ESTEJA PRONTO PARA DESTRUIR
        with status_lock:
            status['message'] = 'Inicializando Terraform para destruição...'
        run_command(['terraform', 'init', '-reconfigure'], TERRAFORM_DIR)

        with status_lock:
            status['message'] = 'Destruindo a infraestrutura...'
        run_command(['terraform', 'destroy', '-auto-approve'], TERRAFORM_DIR)
        
        # Sucesso!
        with status_lock:
            status['current_process'] = 'idle'
            status['message'] = 'Infraestrutura destruída com sucesso. Pronto para iniciar.'
            status['public_ip'] = None

    except Exception as e:
        raw_error_message = str(e)
        sanitized_message = sanitize_terminal_output(raw_error_message)
        with status_lock:
            status['current_process'] = 'error'
            status['message'] = f"{sanitized_message}"
        print(f"Ocorreu um erro: {raw_error_message}")

# --- ROTAS DA API FLASK ---

@app.route('/')
def index():
    """Renderiza a página principal."""
    return render_template('minecraft.html')

@app.route('/start', methods=['POST'])
def start_server():
    """Inicia o processo de criação do servidor."""
    with status_lock:
        if status['current_process'] in ['starting', 'stopping']:
            return jsonify({'message': 'Um processo já está em andamento.'}), 409
        
        status['current_process'] = 'starting'
        status['message'] = 'Comando para iniciar recebido. Iniciando thread...'
        thread = threading.Thread(target=start_minecraft_process)
        thread.start()
        return jsonify({'message': 'O processo de inicialização foi iniciado.'})

@app.route('/stop', methods=['POST'])
def stop_server():
    """Inicia o processo de parada do servidor."""
    with status_lock:
        if status['current_process'] in ['starting', 'stopping']:
            return jsonify({'message': 'Um processo já está em andamento.'}), 409
        
        status['current_process'] = 'stopping'
        status['message'] = 'Comando para parar recebido. Iniciando thread...'
        thread = threading.Thread(target=stop_minecraft_process)
        thread.start()
        return jsonify({'message': 'O processo de backup e parada foi iniciado.'})

@app.route('/status', methods=['GET'])
def get_status():
    """Fornece o status atual para o frontend."""
    with status_lock:
        return jsonify(status)

@app.route('/reset', methods=['POST'])
def reset_status():
    """Reseta o estado para o padrão inicial."""
    with status_lock:
        if status['current_process'] == 'error':
            status['current_process'] = 'idle'
            status['message'] = 'Estado resetado. Pronto para iniciar.'
            status['public_ip'] = None
            status['last_log'] = []
            return jsonify({'message': 'Estado resetado com sucesso.'})
        return jsonify({'message': 'O estado só pode ser resetado a partir de um erro.'}), 400
    
# --- INICIALIZAÇÃO ---
if __name__ == '__main__':
    # Garante que o Terraform esteja inicializado toda vez que o container sobe.
    # Isso é seguro e garante que os plugins estejam prontos.
    # O -reconfigure é útil para garantir que a configuração do backend seja aplicada.

    # print("Inicializando o Terraform no diretório de trabalho com reconfiguração do backend...")
    # subprocess.run(['terraform', 'init', '-reconfigure'], cwd=TERRAFORM_DIR)
    # print("Inicialização do Terraform concluída.")

    print("Servidor Flask pronto para receber comandos.")
    app.run(host='0.0.0.0', port=5001)