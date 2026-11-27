# Changelog

## [Unreleased]

### Added

- A root `.gitattributes` with the shared line-ending block: text files are LF in the repository and in every checkout, `*.bat`/`*.cmd` are CRLF, and common binary extensions are listed.
- CI also runs on the merge queue's `merge_group` event, with `gate` reporting the combined result.
- A `lab-base` adapter for the pinned official Isaac Lab 3.0.0 image, with the duplicate UID 1000 entry removed.
- Recipes to initialize the pinned `isaac` submodule and experimentally build its `devel` image on the adapter.
- Static layout checks, container smoke checks for Python imports, CUDA and user identity, and CI with an optional self-hosted GPU job.
- Setup and image-update instructions in four languages, an architecture decision record and a test inventory.
