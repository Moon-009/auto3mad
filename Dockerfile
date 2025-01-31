# For frontend React
FROM node:14.15.1-alpine3.12 as node_builder

ARG build_path=/go/src/github.com/yangsf5/auto3mad/frontend
WORKDIR $build_path

COPY ./frontend .

RUN mkdir -p $build_path/dist \
  && yarn config set registry 'https://registry.npm.taobao.org' \
  && yarn install \
  && export NODE_OPTIONS=--max_old_space_size=3072 \
  && yarn run build


# For backend Golang
FROM golang:1.17 as go_builder

ENV GOPROXY=https://goproxy.cn,direct

ENV GO111MODULE=on

ENV GOPATH=/go

WORKDIR /go/src/github.com/yangsf5/auto3mad/backend

COPY ./backend .

RUN go build


# For run
FROM debian:buster

COPY source_list_for_buster /etc/apt/sources.list

ARG from_path=/go/src/github.com/yangsf5/auto3mad
ARG run_path=/home/auto3mad


COPY --from=node_builder $from_path/frontend/dist $run_path/static

COPY --from=go_builder $from_path/backend/conf $run_path/conf
COPY --from=go_builder $from_path/backend/backend $run_path/backend

RUN rm -f /etc/localtime \
  && ln -sv /usr/share/zoneinfo/Asia/Chongqing /etc/localtime \
  && echo "Asia/Chongqing" > /etc/timezone

WORKDIR $run_path

ENTRYPOINT ["/home/auto3mad/backend"]

EXPOSE 1127

