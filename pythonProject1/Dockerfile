FROM python:3.9

# Copie o código da aplicação para o diretório de trabalho
WORKDIR /app
COPY . /app

# Instale as dependências
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install grpcio grpcio-tools

# Comando para rodar a aplicação
CMD ["python", "GRPc.py"]