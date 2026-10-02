#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "${script_dir}/.." && pwd)
koka_dir="${repo_dir}/koka"

cd "${koka_dir}"

shopt -s globstar nullglob
test_files=(test/**/*-test.kk)

runner_dir=$(mktemp -d /tmp/shipping-rate-koka-tests.XXXXXX)
trap 'rm -rf "${runner_dir}"' EXIT
runner_file="${runner_dir}/generated-test-main.kk"

imports=()
test_calls=()

for test_file in "${test_files[@]}"; do
  module_name=''
  file_tests=()

  while IFS= read -r line; do
    if [[ -z "${module_name}" && "${line}" =~ ^module[[:space:]]+(.+)$ ]]; then
      module_name="${BASH_REMATCH[1]}"
    elif [[ "${line}" =~ ^pub[[:space:]]+fun[[:space:]]+(test-[A-Za-z0-9-]+)\(\) ]]; then
      file_tests+=("${BASH_REMATCH[1]}")
    fi
  done < "${test_file}"

  if ((${#file_tests[@]} > 0)); then
    if [[ -z "${module_name}" ]]; then
      echo "Missing module declaration: ${test_file}" >&2
      exit 1
    fi

    imports+=("import ${module_name}")
    for test_name in "${file_tests[@]}"; do
      test_calls+=("  ${module_name}/${test_name}()")
    done
  fi
done

if ((${#test_calls[@]} == 0)); then
  echo "No Koka tests found." >&2
  exit 1
fi

{
  echo 'module generated-test-main'
  echo
  echo 'import std/async'
  printf '%s\n' "${imports[@]}"
  echo
  echo 'fun main() : <console,async,exn> ()'
  printf '%s\n' "${test_calls[@]}"
  echo "  println(\"${#test_calls[@]} tests passed\")"
} > "${runner_file}"

koka \
  --execute \
  --target=jsnode \
  --builddir=.koka \
  --include="${runner_dir}" \
  --include=src \
  "${runner_file}"
