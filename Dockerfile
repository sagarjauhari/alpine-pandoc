# https://hub.docker.com/r/portown/alpine-pandoc/~/dockerfile/
#
# We use:
# * Pandoc (Haskell) to convert all Markdown into either generated HTML or .rst files.
#

FROM alpine:3.10

ENV BUILD_DEPS \
    alpine-sdk \
    cabal \
    coreutils \
    ghc \
    libffi \
    musl-dev \
    zlib-dev
ENV PERSISTENT_DEPS \
    gmp \
    graphviz \
    openjdk11-jre \
    python \
    py2-pip \
    sed \
    ttf-droid \
    ttf-droid-nonlatin


ENV PANDOC_VERSION 2.9.2.1
ENV PANDOC_DOWNLOAD_URL https://hackage.haskell.org/package/pandoc-$PANDOC_VERSION/pandoc-$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc

ENV PATH $PATH:$PANDOC_ROOT/bin

# Install/Build Packages
RUN apk upgrade --update && \
    apk add --virtual .build-deps $BUILD_DEPS && \
    apk add --virtual .persistent-deps $PERSISTENT_DEPS && \
    mkdir -p /var/docs

WORKDIR /pandoc-build
RUN curl -fsSL "$PANDOC_DOWNLOAD_URL" | tar -xzf -

WORKDIR /pandoc-build/pandoc-$PANDOC_VERSION
RUN cabal new-update
RUN cabal new-install --only-dependencies
RUN cabal new-configure --prefix=$PANDOC_ROOT
RUN cabal new-build
RUN cabal new-copy

WORKDIR /
RUN rm -Rf /pandoc-build \
           $PANDOC_ROOT/lib \
           /root/.cabal \
           /root/.ghc && \
    set -x && \
    addgroup -g 82 -S pandoc && \
    adduser -u 82 -D -S -G pandoc pandoc && \
    apk del .build-deps


# Set to non root user
USER pandoc

# Reset the work dir
WORKDIR /var/docs
