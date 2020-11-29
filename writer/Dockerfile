FROM perl:5.32 AS build
RUN cpanm Carton

WORKDIR /app
COPY cpanfile .

RUN carton install

FROM alpine:3
RUN apk add perl perl-dbi perl-dbd-pg perl-moose

WORKDIR /app
COPY . .
COPY --from=build /app/local .
ENV PERL5LIB=/app/lib/perl5
