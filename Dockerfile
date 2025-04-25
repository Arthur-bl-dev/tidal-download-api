# Usando uma imagem base com Python
FROM python:3.10-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos do projeto para o container
COPY . /app

# Instala dependências
RUN pip install --no-cache-dir fastapi>=0.104.0 uvicorn>=0.23.2 python-multipart>=0.0.6 \
    && pip install --no-cache-dir tidal-dl==2022.10.31.1

# Expõe a porta usada pela aplicação FastAPI
EXPOSE 38880

# Comando para rodar o servidor
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "38880"]
