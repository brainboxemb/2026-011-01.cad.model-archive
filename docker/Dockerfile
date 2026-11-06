# Dedicated documentation runtime for the model archive.
# Extends the existing BrainboxEmb OpenSCAD image; no changes to the shared
# docker.scad-toolchain or its published profiles are necessary.
#
# NopSCADlib currently requires ImageMagick 7 (the 'magick' command). Ubuntu
# 24.04's imagemagick package is ImageMagick 6, so build version 7 explicitly.

FROM ubuntu:24.04 AS imagemagick-build

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGEMAGICK_VERSION=7.1.2-1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl build-essential pkg-config libpng-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN set -eux; \
    curl -fL "https://github.com/ImageMagick/ImageMagick/archive/refs/tags/${IMAGEMAGICK_VERSION}.tar.gz" \
        -o imagemagick.tar.gz; \
    mkdir imagemagick-source; \
    tar -xzf imagemagick.tar.gz -C imagemagick-source --strip-components=1; \
    cd imagemagick-source; \
    ./configure \
        --prefix=/opt/imagemagick \
        --disable-static \
        --disable-openmp \
        --without-perl \
        --without-magick-plus-plus \
        --with-modules=no \
        --with-png=yes \
        --without-jpeg \
        --without-tiff \
        --without-webp \
        --without-heic \
        --without-freetype; \
    make -j2; \
    make install

FROM ghcr.io/brainboxemb/scad-toolchain-openscad:v0.6.1

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGEMAGICK_VERSION=7.1.2-1

LABEL org.opencontainers.image.title="BrainboxEmb model archive / NopSCADlib"
LABEL org.opencontainers.image.source="https://github.com/brainboxemb/2026-011-01.cad.model-archive"
LABEL org.opencontainers.image.description="OpenSCAD, upstream NopSCADlib build prerequisites, ImageMagick 7"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng16-16t64 python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=imagemagick-build /opt/imagemagick /opt/imagemagick

ENV PATH="/opt/imagemagick/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/imagemagick/lib:${LD_LIBRARY_PATH}" \
    MAGICK_HOME="/opt/imagemagick" \
    IMAGEMAGICK_VERSION="${IMAGEMAGICK_VERSION}" \
    QT_QPA_PLATFORM=offscreen

# Upstream NopSCADlib docs/usage.md names these Python dependencies.
RUN python3 -m pip install --no-cache-dir --break-system-packages \
        "colorama==0.4.6" \
        "Markdown==3.9" \
        "codespell==2.4.1" \
        "vcs2l==1.1.7" \
    && magick -version | grep -q 'ImageMagick 7' \
    && python -c 'import colorama, markdown; assert colorama and markdown' \
    && codespell --version \
    && vcs --help >/dev/null \
    && command -v openscad \
    && command -v xvfb-run

# The repository and the fetched NopSCADlib checkout are mounted at run time.
# Keep the BOSL2 path inherited from the base image when mounting externals.
ENV OPENSCADPATH="/work/ext:/opt/openscad-libraries"
WORKDIR /work
CMD ["bash"]
