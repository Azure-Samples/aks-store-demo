# Escolha a imagem base do Python
FROM python:3.9

# Defina o diretório de trabalho
WORKDIR /app

# Copie o arquivo requirements.txt para a imagem
COPY requirements.txt .

# Instale as dependências do requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copie o restante do código da aplicação
COPY . .

# Comando para rodar a aplicação
CMD ["python", "GRPc.py"]
