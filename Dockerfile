# Dockerfile - adapter over the official Isaac Lab image.
#
# isaac_lab differs from ycpss91255-lab/isaac in ONE thing: the base image.
# isaac builds on nvcr.io/nvidia/isaac-sim and installs Isaac Lab itself;
# isaac_lab starts from the official nvcr.io/nvidia/isaac-lab image, which
# already ships Isaac Sim + Isaac Lab. This Dockerfile only adapts that image
# to the conventions isaac expects, so isaac's own Dockerfile can be built on
# top of it through its BASE_IMAGE build arg (see doc/adr/0001-*.md). No
# isaac code is copied here.
#
# Isaac Lab 3.0.0 targets Isaac Sim 6.2.0 (rc.14). The tag is pinned together
# with its digest so a re-pushed tag cannot change the build.
ARG BASE_IMAGE="nvcr.io/nvidia/isaac-lab:3.0.0@sha256:f70acc9ed3bc3fc67099a0c5715379c432cc9965623cabbaf54f74599997e245"

# hadolint ignore=DL3006
FROM ${BASE_IMAGE} AS lab-base

# hadolint ignore=DL3002
USER root

# The official image has two passwd entries for UID 1000 (ubuntu and
# isaaclab, HOME=/root). A user created later for the host UID then resolves
# sudo to the other name and NOPASSWD never matches (isaac#473 Revision 1).
# Drop the extra entry (no -r: its home is /root). User creation itself is
# isaac#474's job and is not duplicated here.
RUN userdel isaaclab 2>/dev/null || true

# Isaac Lab lives in the uv venv /opt/isaaclab-venv, not in Isaac Sim's own
# python, so run Python through `${ISAACLAB_PATH}/isaaclab.sh -p`
# (/isaac-sim/python.sh cannot import isaaclab or torch here).
ENV ISAACLAB_PATH=/workspace/isaaclab
