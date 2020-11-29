FROM golang:1.14-alpine AS build

ENV CGO_ENABLED=no
WORKDIR /usr/src
COPY . .
RUN go build -o /bdaynoc .

FROM alpine:3
COPY --from=build /bdaynoc /bdaynoc
ENTRYPOINT ["/bdaynoc"]
