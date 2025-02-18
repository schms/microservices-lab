FROM klakegg/hugo:0.111.3-ext-ubuntu AS builder

ARG TRAINING_HUGO_ENV=default

COPY . /src

RUN hugo --environment ${TRAINING_HUGO_ENV} --minify

RUN apt-get update \
    && apt-get install -y imagemagick

RUN find /src/public/docs/ -regex '.*\(jpg\|jpeg\|png\|gif\)' -exec mogrify -path /src/public/pdf -resize 800\> -unsharp 0.25x0.25+8+0.065 "{}" \;
RUN find /src/public/docs/ -regex '.*\(jpg\|jpeg\|png\|gif\)' -exec mogrify -path /src/public -resize 800\> -unsharp 0.25x0.25+8+0.065 "{}" \;

FROM ubuntu:jammy AS wkhtmltopdf
RUN apt-get update \
    && apt-get install -y curl \
    && curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb --output wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && ls -la \
    && apt-get install -y /wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /wkhtmltox_0.12.6.1-2.jammy_amd64.deb

COPY --from=builder /src/public /

# RUN wkhtmltopdf --enable-internal-links --enable-local-file-access \
#     --margin-top 35mm --margin-bottom 22mm --margin-left 15mm --margin-right 10mm \
#     --enable-internal-links --enable-local-file-access \
#     --header-html /pdf/header/index.html --footer-html /pdf/footer/index.html \
#     --dpi 600 \
#     /pdf/index.html /pdf.pdf

FROM nginxinc/nginx-unprivileged:1.25-alpine

LABEL maintainer acend.ch

EXPOSE 8080

COPY --from=builder /src/public /usr/share/nginx/html
# COPY --from=wkhtmltopdf /pdf.pdf /usr/share/nginx/html/pdf/pdf.pdf
