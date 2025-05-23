# Smile Digital Health Helm Charts Contribution Workflow

This document serves as a working reference to be used when working on feature requests for the Smile Digital Health Helm Charts.

---

## Documentation Development

Documentation is auto-generated using [MkDocs](https://www.mkdocs.org/) + [Material theme](https://squidfunk.github.io/mkdocs-material/).

- Document source code lives in: `./docs/`
- Documents are published here: https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/

### Editing Docs Locally

To ease the process of editing the docs, you can run a live local version that updates in realtime as you make changes to the documentation source code.

This local environment can be created automatically using the `makefile` or you can create the environment manually.

#### Using Makefile
```sh
make mkdocs-serve
```
- Local version of docs available at: http://127.0.0.1:8000/smile-dh-helm-charts/

> 💡 Changes you make in the `docs/` folder will reload automatically.

#### Manual Setup
```sh
python3 -m venv venv
. ./venv/bin/activate
pip install -r mkdocs-requirements.txt
mkdocs serve
```
