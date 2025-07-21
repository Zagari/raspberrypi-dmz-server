terraform {
  backend "s3" {
    bucket         = "meu-projeto-server-castellabate-terraform-state" # ← O mesmo nome do bucket que você criou
    key            = "global/server-castellabate/terraform.tfstate"      # O caminho/nome do arquivo de estado dentro do bucket
    region         = "us-east-1"
    dynamodb_table = "meu-projeto-server-castellabate-terraform-lock" # ← O nome da tabela DynamoDB que você criou
  }
}