.PHONY: dependencies-up dependencies-down run test test-new test-all run-ts test-ts run-effect-ts test-effect-ts run-ps run-ps-mtl test-ps run-ps-run test-ps-run run-koka test-koka run-kyo test-kyo run-flix test-flix run-polysemy test-polysemy run-effectful test-effectful run-ocaml-eio-capabilities test-ocaml-eio-capabilities run-ocaml-eio-effects test-ocaml-eio-effects

SPAGO_CACHE ?= $(CURDIR)/.cache/spago
OCAML_EXEC ?= opam exec --
TEST_ALL_TARGETS := test-ts test-ps test-koka test-effect-ts test-kyo test-flix test-polysemy test-effectful test-ps-run test-ocaml-eio-capabilities test-ocaml-eio-effects
RUN_ALL_TARGETS := run-ts run-ps-mtl run-koka run-effect-ts run-kyo run-flix run-polysemy run-effectful run-ps-run run-ocaml-eio-capabilities run-ocaml-eio-effects

dependencies-up:
	docker compose up --detach --wait

dependencies-down:
	docker compose down

run: $(RUN_ALL_TARGETS)

test: test-ts test-ps test-koka

test-new: test-effect-ts test-kyo test-flix test-polysemy test-effectful test-ps-run test-ocaml-eio-capabilities test-ocaml-eio-effects

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

run-ps: run-ps-mtl

run-ps-mtl:
	cd purescript-mtl && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago run

test-ps:
	cd purescript-mtl && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago test

run-koka:
	cd koka && koka --execute --target=jsnode --builddir=.koka --include=src src/main.kk

test-koka:
	./scripts/run-koka-tests.sh

run-kyo:
	cd scala-kyo && scala-cli run . --server=false

test-kyo:
	cd scala-kyo && scala-cli test . --server=false

run-flix:
	cd flix && java --enable-native-access=ALL-UNNAMED -jar flix.jar run

test-flix:
	cd flix && java --enable-native-access=ALL-UNNAMED -jar flix.jar test

run-polysemy:
	cd haskell-polysemy && stack run

test-polysemy:
	cd haskell-polysemy && stack test

run-effectful:
	cd haskell-effectful && stack run

test-effectful:
	cd haskell-effectful && stack test

run-ps-run:
	cd purescript-run && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago run

test-ps-run:
	cd purescript-run && XDG_CACHE_HOME="$(SPAGO_CACHE)" spago test

run-ocaml-eio-capabilities:
	cd ocaml-eio-capabilities && $(OCAML_EXEC) dune exec bin/main.exe

test-ocaml-eio-capabilities:
	cd ocaml-eio-capabilities && $(OCAML_EXEC) dune build @fmt && $(OCAML_EXEC) dune runtest --force

run-ocaml-eio-effects:
	cd ocaml-eio-effects && $(OCAML_EXEC) dune exec bin/main.exe

test-ocaml-eio-effects:
	cd ocaml-eio-effects && $(OCAML_EXEC) dune build @fmt && $(OCAML_EXEC) dune runtest --force
