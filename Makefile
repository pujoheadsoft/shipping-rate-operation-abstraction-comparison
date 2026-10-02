.PHONY: run test run-ts test-ts run-ps test-ps run-koka test-koka

run: run-ts run-ps run-koka

test: test-ts test-ps test-koka

run-ts:
	cd typescript && deno task start

test-ts:
	cd typescript && deno task test

run-ps:
	cd purescript && spago run

test-ps:
	cd purescript && spago test

run-koka:
	cd koka && koka --execute --target=jsnode --builddir=.koka --include=src src/main.kk

test-koka:
	./scripts/run-koka-tests.sh
