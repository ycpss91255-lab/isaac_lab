# isaac_lab task runner. Image names use the cc- prefix.
image := "ycpss91255/cc-lab-base:local"
tools := env_var_or_default("TEST_TOOLS_IMAGE", "ghcr.io/ycpss91255-lab/test-tools:latest")

default:
    @just --list

# Check out the pinned upstream source.
submodule:
    git submodule update --init

# Build the adapter image (official isaac-lab + adaptations).
build:
    docker build --target lab-base -t {{image}} .

# Experimental until upstream removes its own Isaac Lab installation.
build-isaac: build
    docker build -f isaac/Dockerfile --build-arg BASE_IMAGE={{image}} --target devel -t ycpss91255/cc-lab-isaac:local isaac/

# Container smoke: needs Docker + NVIDIA GPU.
smoke: build
    ./test/smoke/image_smoke.sh {{image}}

# Static bats specs (run in the test-tools image, never on the host).
test:
    docker run --rm -v "{{justfile_directory()}}":/work -w /work {{tools}} bats test/bats/smoke

# Lint: hadolint + shellcheck (in the test-tools image).
lint:
    docker run --rm -v "{{justfile_directory()}}":/work -w /work {{tools}} sh -c 'hadolint --config .hadolint.yaml Dockerfile && shellcheck test/smoke/*.sh script/ci/*.sh'
