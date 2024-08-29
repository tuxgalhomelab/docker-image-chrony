# syntax=docker/dockerfile:1

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS with-configs-and-scripts

COPY config/chrony.conf /configs/
COPY scripts/start-chrony.sh /scripts/

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG PACKAGES_TO_INSTALL
ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID

RUN \
    --mount=type=bind,target=/configs,from=with-configs-and-scripts,source=/configs \
    --mount=type=bind,target=/scripts,from=with-configs-and-scripts,source=/scripts \
    set -E -e -o pipefail \
    && export HOMELAB_VERBOSE=y \
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
    && mkdir -p /opt/chrony /data/chrony /run/chrony /var/lib/chrony \
    && cp /configs/chrony.conf /data/chrony/chrony.conf \
    # Copy the start-chrony.sh script. \
    && cp /scripts/start-chrony.sh /opt/chrony/ \
    && ln -sf /opt/chrony/start-chrony.sh /opt/bin/start-chrony \
    && chown -R ${USER_NAME:?}:${GROUP_NAME:?} /opt/chrony /opt/bin/start-chrony /data/chrony /run/chrony /var/lib/chrony \
    && chmod 0750 /run/chrony \
    # Clean up. \
    && homelab cleanup

# Chrony NTP server.
EXPOSE 123/udp

# Use chronyc tracking command as the health checker.
HEALTHCHECK --start-period=15s --interval=30s --timeout=3s CMD chronyc -n tracking

USER ${USER_NAME}:${GROUP_NAME}
WORKDIR /

CMD ["start-chrony"]
STOPSIGNAL SIGTERM
