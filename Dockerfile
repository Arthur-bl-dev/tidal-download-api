# Imagem base otimizada
FROM python:3.10-slim

# Define o ambiente como produção (otimiza o Python)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instala dependências do sistema em uma única camada
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Define diretório de trabalho
WORKDIR /app

# Copia apenas os arquivos de requisitos primeiro (melhor cache)
COPY requirements.txt .

# Instala dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do código
COPY . .

# Cria diretório de downloads com permissão total
RUN mkdir -p /app/downloads && chmod 777 /app/downloads

# Script de inicialização que verifica a configuração do tidal-dl
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expõe a porta da API (configurável via variável de ambiente)
EXPOSE ${PORT:-38880}

# Comando de entrada que executa o script de inicialização
ENTRYPOINT ["/entrypoint.sh"]

# Comando padrão que será passado para o entrypoint
CMD ["start-api"] 