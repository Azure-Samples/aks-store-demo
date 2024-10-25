FROM python:3.9

# Copie o código da aplicação para o diretório de trabalho
WORKDIR /app
COPY . /app

# Instale os pacotes manualmente para debug
RUN pip install grpcio grpcio-tools

# Comando para rodar a aplicação
CMD ["python", "GRPc.py"]