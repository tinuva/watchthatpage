FROM golang as builder

COPY . /go/
RUN go get -d ./...
RUN go install -ldflags "-d -s -w -X tensin.org/watchthatpage/core.Build=`git rev-parse HEAD`" -a -tags netgo -installsuffix netgo tensin.org/watchthatpage

######################################

FROM ubuntu:17.10

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	apt-get install -q -y xvfb libfontconfig openssl ca-certificates bash cron && \
	apt-get install -q -y build-essential xorg libssl-dev libxrender-dev wget
	apt-get clean

RUN wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
    tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

COPY resources /resources
COPY --from=builder /go/bin/watchthatpage /bin/watchthatpage

RUN echo "0 * * * * cd / && watchthatpage grab > /proc/1/fd/1 2> /proc/1/fd/2" | crontab -

ENTRYPOINT ["/init"]
CMD ["cron", "-f"]
