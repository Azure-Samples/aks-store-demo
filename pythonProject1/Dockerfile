FROM python:3.9-slim
WORKDIR /app
COPY . .
# Instale as dependências do Python, usando o requirements.txt, se tiver
RUN pip install --no-cache-dir requests
# Execute o seu script Python
CMD ["python", "GRPc.py"]