.PHONY: run test test-new test-all run-ts test-ts run-effect-ts test-effect-ts run-ps test-ps run-koka test-koka test-kyo test-flix test-polysemy test-effectful test-ps-run

SPAGO_CACHE ?= $(CURDIR)/.cache/spago
TEST_ALL_TARGETS := test-ts test-ps test-koka test-effect-ts test-kyo test-flix test-polysemy test-effectful test-ps-run

run: run-ts run-effect-ts run-ps run-koka

test: test-ts test-ps test-koka

test-new: test-effect-ts test-kyo test-flix test-polysemy test-effectful test-ps-run

test-all:
	@set -u; \
	log_dir=$$(mktemp -d); \
	trap 'rm -rf "$$log_dir"' EXIT; \
	trap 'exit 130' HUP INT TERM; \
	printf 'Running %s test suites in parallel...\n' "$(words $(TEST_ALL_TARGETS))"; \
	for target in $(TEST_ALL_TARGETS); do \
		( \
			$(MAKE) --no-print-directory "$$target" >"$$log_dir/$$target.log" 2>&1; \
			printf '%s\n' "$$?" >"$$log_dir/$$target.status"; \
		) & \
	done; \
	wait; \
	for target in $(TEST_ALL_TARGETS); do \
		printf '\n=== %s ===\n' "$$target"; \
		cat "$$log_dir/$$target.log"; \
	done; \
	failed=0; \
	printf '\n=== Test summary ===\n'; \
	for target in $(TEST_ALL_TARGETS); do \
		status=1; \
		if test -f "$$log_dir/$$target.status"; then \
			status=$$(cat "$$log_dir/$$target.status"); \
		fi; \
		if test "$$status" -eq 0; then \
			printf 'PASS  %s\n' "$$target"; \
		else \
			printf 'FAIL  %s (exit %s)\n' "$$target" "$$status"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if test "$$failed" -eq 0; then \
		printf 'All %s test suites passed.\n' "$(words $(TEST_ALL_TARGETS))"; \
	else \
		printf '%s of %s test suites failed.\n' "$$failed" "$(words $(TEST_ALL_TARGETS))"; \
		exit 1; \
	fi

run-ts:
	cd typescript && deno task start

test-ts:
	cd typescript && deno task test

run-effect-ts:
	cd typescript-effect && npm start

test-effect-ts:
	cd typescript-effect && npm run format:check && npm run typecheck && npm test

run-ps:
	cd purescript-mtl && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago run

test-ps:
	cd purescript-mtl && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago test

run-koka:
	cd koka && koka --execute --target=jsnode --builddir=.koka --include=src src/main.kk

test-koka:
	./scripts/run-koka-tests.sh

test-kyo:
	cd scala-kyo && scala-cli test . --server=false

test-flix:
	cd flix && java -jar "$$HOME/.local/share/flix.jar" test

test-polysemy:
	cd haskell-polysemy && stack test

test-effectful:
	cd haskell-effectful && stack test

test-ps-run:
	cd purescript-run && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago test
