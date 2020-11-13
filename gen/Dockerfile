FROM perl:5.32
RUN cpanm Carton

WORKDIR /app
COPY cpanfile .

COPY . .
RUN carton install
