.PHONY: help run-all-tests build helm-update-outputs helm-update-outputs-force helm-check-outputs helm-lint

help:
	    @echo "Smile Digital Healh helm charts"
	    @echo ""
	    @echo "Commands:"
	    @echo "run-all-tests - run all tests, duh! Currently only runs check-helm-outputs"
		@echo "build - TBD. Needs to update helm outputs, increment chart version etc"
	    @echo "helm-check-outputs - run tests to make sure helm template gives expected output"
		@echo "helm-update-outputs - update expected output files for helm template if they differ semantically"
		@echo "helm-update-outputs-force - force update of expected output files for helm template"
		@echo "helm-lint - run helm lint on all charts"

.DEFAULT_GOAL := help

run-all-tests: helm-lint check-helm-outputs

build: update-helm-outputs

helm-update-outputs-force:
	./scripts/check-outputs.sh -f ./src

helm-update-outputs:
	./scripts/check-outputs.sh -u ./src

helm-check-outputs: helm-lint
	./scripts/check-outputs.sh ./src

helm-lint:
	./scripts/lint-charts.sh ./src


include Makefile-local
