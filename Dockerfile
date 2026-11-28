ARG BASE_IMAGE="nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245"
ARG TEST_TOOLS_IMAGE="ghcr.io/ycpss91255-lab/test-tools:v0.43.0-rc7"

FROM ${BASE_IMAGE} AS base
RUN id -g > /tmp/lab-gid

FROM base AS sys
ARG USER_NAME=user
ARG USER_GROUP=${USER_NAME}
ARG USER_UID=1000
ARG USER_GID=1000
ARG TZ=Asia/Taipei
ARG APT_MIRROR_UBUNTU=archive.ubuntu.com

# hadolint ignore=DL3002,DL3066
USER root
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ENV ISAACLAB_PATH=/workspace/isaaclab
ENV TZ=${TZ}

# The pinned image has ubuntu and isaaclab at UID 1000. Keep the files
# owned by that UID, including isaaclab's home directory (/root).
# A host login such as ubuntu may also have a different numeric ID.
RUN userdel isaaclab && \
    if old_gid="$(getent group "${USER_GROUP}" | cut -d: -f3)" && [ "${old_gid}" != "${USER_GID}" ]; then \
        groupmod -n "base-${USER_GROUP}" "${USER_GROUP}"; \
    fi && \
    if ! getent group "${USER_GROUP}" >/dev/null; then \
        if entry="$(getent group "${USER_GID}")"; then \
            groupmod -n "${USER_GROUP}" "${entry%%:*}"; \
        else \
            groupadd -g "${USER_GID}" "${USER_GROUP}"; \
        fi; \
    fi && \
    if old_uid="$(id -u "${USER_NAME}" 2>/dev/null)" && [ "${old_uid}" != "${USER_UID}" ]; then \
        usermod -l "base-${USER_NAME}" "${USER_NAME}"; \
    fi && \
    if entry="$(getent passwd "${USER_UID}")"; then \
        usermod -l "${USER_NAME}" -d "/home/${USER_NAME}" -s /bin/bash "${entry%%:*}"; \
    else \
        useradd -l -m -s /bin/bash -u "${USER_UID}" -g "${USER_GID}" "${USER_NAME}"; \
    fi && \
    usermod -g "${USER_GID}" -aG "$(cat /tmp/lab-gid)" "${USER_NAME}" && \
    install -d -o "${USER_UID}" -g "${USER_GID}" "/home/${USER_NAME}"

FROM sys AS devel-base
# Install development tools from the configured Ubuntu mirror.
# hadolint ignore=DL3008
RUN for source in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do \
        if [ -f "$source" ]; then sed -i "s|archive.ubuntu.com|${APT_MIRROR_UBUNTU}|g" "$source"; fi; \
    done && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git sudo && \
    rm -rf /var/lib/apt/lists/* && \
    printf '#%s ALL=(ALL) NOPASSWD:ALL\n' "${USER_UID}" > /etc/sudoers.d/host-user && \
    chmod 0440 /etc/sudoers.d/host-user

FROM devel-base AS devel
COPY --chmod=0755 script/entrypoint.sh /entrypoint.sh
ENV USER_NAME=${USER_NAME} USER_UID=${USER_UID} HOME=/home/${USER_NAME}
ENV DOCKER_USER_HOME=${HOME}
USER ${USER_NAME}
RUN mkdir -p "${HOME}/work" "${HOME}/.cache" "${HOME}/.nv"
WORKDIR ${HOME}/work
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

FROM ${TEST_TOOLS_IMAGE} AS test-tools-stage
FROM devel AS devel-test
COPY --from=test-tools-stage /usr/local/bin/shellcheck /usr/local/bin/hadolint /usr/local/bin/
COPY --from=test-tools-stage /opt/bats /opt/bats
COPY --from=test-tools-stage /usr/lib/bats /usr/lib/bats
ENV PATH="/opt/bats/bin:${PATH}" BATS_LIB_PATH=/usr/lib/bats
COPY Dockerfile .hadolint.yaml script/entrypoint.sh /lint/
COPY .base/dist/script/docker/wrapper/ /lint/
COPY .base/dist/script/docker/lib/ /lint/lib/
COPY script/ci/ /lint/ci/
COPY script/hooks/ /lint/hooks/
COPY script/local/local.sh /lint/local.sh
RUN hadolint --config /lint/.hadolint.yaml /lint/Dockerfile && \
    shellcheck -S warning /lint/*.sh /lint/lib/*.sh /lint/ci/*.sh /lint/hooks/*/*.sh
COPY .base/dist/test/bats/smoke/shared/ /smoke_test/
COPY .base/dist/test/bats/smoke/devel-test/ /smoke_test/
COPY test/bats/smoke/devel-test/ /smoke_test/
RUN bats /smoke_test/
CMD ["sleep", "infinity"]

FROM devel AS headless
CMD ["sleep", "infinity"]
