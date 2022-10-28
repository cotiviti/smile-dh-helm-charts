.PHONY: help run-all-tests build update-helm-outputs check-helm-outputs

help:
	    @echo "Smile Digital Healh helm charts"
	    @echo ""
	    @echo "Commands:"
	    @echo "run-all-tests - run all tests, duh! Currently only runs check-helm-outputs"
		@echo "build - TBD. Needs to update helm outputs, increment chart version etc"
	    @echo "check-helm-outputs - run tests to make sure helm template gives expected output"
		@echo "update-helm-outputs - update expected output files for helm template"

.DEFAULT_GOAL := help

run-all-tests: check-helm-outputs

build: update-helm-outputs

update-helm-outputs:
	./scripts/check-outputs.sh -u ./src

check-helm-outputs:
	./scripts/check-outputs.sh ./src
