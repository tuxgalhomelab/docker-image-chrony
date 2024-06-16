# syntax=docker/dockerfile:1.3

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS with-configs

COPY config/chrony.conf /configs/

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

ARG PACKAGES_TO_INSTALL
ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID

RUN --mount=type=bind,target=/configs,from=with-configs,source=/configs \
    set -E -e -o pipefail \
    # Create the user and the group. \
    && homelab add-user \
        ${USER_NAME:?} \
        ${USER_ID:?} \
        ${GROUP_NAME:?} \
        ${GROUP_ID:?} \
        --no-create-home-dir \
    # Install dependencies. \
    && homelab install util-linux ${PACKAGES_TO_INSTALL:?} \
    && homelab remove util-linux \
    && mkdir -p /chrony /run/chrony /var/lib/chrony \
    && cp /configs/chrony.conf /chrony/chrony.conf \
    && chown -R ${USER_NAME:?}:${GROUP_NAME:?} /chrony /run/chrony /var/lib/chrony \
    && chmod 0750 /run/chrony \
    # Clean up. \
    && homelab cleanup

# Chrony NTP server.
EXPOSE 123/udp

# Use chronyc tracking command as the health checker.
HEALTHCHECK CMD chronyc -n tracking || exit 1

USER ${USER_NAME}:${GROUP_NAME}
WORKDIR /
CMD ["/usr/sbin/chronyd", "-4", "-d", "-U", "-u", "chrony", "-x", "-L", "0", "-f", "/chrony/chrony.conf"]
