from flask import Flask
app = Flask(__name__)

@app.route('/')
def index():
    return "<h1>Flask está funcionando via Nginx Reverse Proxy!</h1>"

# Sem app.run() aqui, o Gunicorn cuida disso.