.PHONY: help run-all-tests build update-helm-outputs check-helm-outputs helm-lint

help:
	    @echo "Smile Digital Healh helm charts"
	    @echo ""
	    @echo "Commands:"
	    @echo "run-all-tests - run all tests, duh! Currently only runs check-helm-outputs"
		@echo "build - TBD. Needs to update helm outputs, increment chart version etc"
	    @echo "check-helm-outputs - run tests to make sure helm template gives expected output"
		@echo "update-helm-outputs - update expected output files for helm template"
		@echo "helm-lint - run helm lint on all charts"

.DEFAULT_GOAL := help

run-all-tests: helm-lint check-helm-outputs

build: update-helm-outputs

update-helm-outputs:
	./scripts/check-outputs.sh -u ./src

check-helm-outputs: helm-lint
	./scripts/check-outputs.sh ./src

helm-lint:
	./scripts/lint-charts.sh ./src


include Makefile-local
