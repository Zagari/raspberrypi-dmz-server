
# Castellabate Infra - Terraform AWS EC2 Spot + VPC

Este projeto provisiona uma infraestrutura completa na AWS usando Terraform. Ele cria uma VPC do zero, com uma instância EC2 Spot (ARM64) que executa múltiplos containers Docker como NGINX, Flask e Minecraft Forge.

---

## ✅ Recursos Criados

- VPC personalizada `10.0.0.0/16`
- Subnet pública `10.0.1.0/24`
- Internet Gateway + Tabela de rotas públicas
- Instância EC2 Spot `t4g.large` (ARM64, 2vCPU, 8GB RAM)
- Comportamento Spot:
  - Tipo: `persistent`
  - Interrupção: `stop`
- Ubuntu Server 22.04 LTS ARM64 (`ami-050499786ebf55a6a`)
- Volume EBS de 40 GB (gp3)
- IP Público (não estamos usando IP fixo do Elastic IP)
- Security Group com portas liberadas: `22`(SSH), `80` (HTTP), `443` (HTTPS), `25565` (Minecraft)
- Script de inicialização para instalação do Docker
- Scripts para iniciar/parar a instância manualmente

---

## ⚙️ Pré-requisitos

- Conta AWS com credenciais configuradas (`aws configure`)
- Chave SSH criada e pública disponível em `~/.ssh/id_ed25519.pub`
- [Terraform](https://developer.hashicorp.com/terraform/install) instalado (`>= 1.5`)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) instalado
- Se precisar, suba seus secrets no Parameter Store (via AWS Console ou CLI):
```bash

aws ssm put-parameter --name "cloudflare_api_token" --value "SEU_TOKEN" --type "SecureString"
aws ssm put-parameter --name "cloudflare_zone_id" --value "..." --type "SecureString"
aws ssm put-parameter --name "cloudflare_record_id" --value "..." --type "SecureString"
aws ssm put-parameter --name "cloudflare_record_name" --value "..." --type "SecureString"

```
---

## 📁 Estrutura

```
.
├── main.tf              # EC2, Security Group, EIP, Instance + IAM Profile
├── vpc.tf               # VPC, Subnet, Internet Gateway, Route Table
├── iam.tf               # IAM Role e políticas para acesso ao SSM
├── outputs.tf           # IP público, ID da instância
├── user_data.sh         # Script inicial da EC2 para instalar Docker e rodar containers
├── stop.sh              # Script para parar a instância manualmente
├── start.sh             # Script para iniciar a instância manualmente
```
  
---

## 🚀 Como usar

### 1. Clone o repositório e entre no diretório

```bash
git clone <repo>
cd <repo>
```

### 2. Inicializar o Terraform

```bash
terraform init
```

### 3. Ajuste o arquivo `main.tf` se necessário

- Certifique-se de que `key_name` seja o mesmo nome da chave SSH já registrada no console AWS
- A chave pública deve estar no caminho `~/.ssh/id_ed25519.pub`

### 4. Importe a chave já existente na AWS (se aplicável)

```bash
terraform import aws_key_pair.main castellabate-key
```

### 5. Aplicar a infraestrutura

```bash
terraform apply -auto-approve
```

Aceite a criação quando solicitado.

### 6. Obter IP público

```bash
terraform output
```

Use esse IP para apontar seu domínio no Cloudflare.

---

## 🧃 Controle manual da instância

### Parar a instância:

```bash
bash stop.sh
```

### Iniciar novamente:

```bash
bash start.sh
```

---

## 🧹 Destruir toda a infraestrutura

```bash
terraform destroy -auto-approve
```

Isso apaga a EC2, IP, VPC e todos os recursos associados.

---

## 📌 Próximos passos

- Adicionar Lambda Functions para agendar start/stop automático
- Automatizar deploy com CI/CD

---

## 🧑‍💻 Autor

Nicola Zagari – Projeto Castellabate.tech 🚀


## 💡 Observações

- A instância Spot será interrompida (mas **não destruída**) caso a AWS precise da capacidade.
- O volume EBS permanece intacto, então seus containers e dados persistem entre interrupções.
- Você pode controlar a ativação/desativação com scripts Terraform ou futuras automações com AWS Lambda.
- Se você já tem uma chave chamada `castellabate-key` na região `us-east-1`, edite o `main.tf` para **comentar** a criação da chave
```hcl
# resource "aws_key_pair" "main" {
#   key_name   = "castellabate-key"
#   public_key = file("~/.ssh/id_ed25519.pub")
# }
```

E, em seguida, importe a chave manualmente para o Terraform com:

```bash
terraform import aws_key_pair.main castellabate-key
```

Assim, o Terraform reconhece e gerencia a chave existente sem tentar recriá-la.
