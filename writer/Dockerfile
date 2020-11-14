FROM perl:5.32 AS build
RUN cpanm Carton

WORKDIR /app
COPY cpanfile .

RUN carton install

FROM alpine:3
RUN apk add perl

WORKDIR /app
COPY . .
COPY --from=build /app/local .
