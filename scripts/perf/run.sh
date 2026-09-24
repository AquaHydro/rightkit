#!/bin/sh
set -eu

cd "$(dirname "$0")/../.."
products="$PWD/.build/DerivedData/Build/Products/Debug"
bundle="$products/RightKitTests.xctest/Contents/Resources/RightKitCore_RightKitCore.bundle"
if [ ! -f "$products/RightKitCore.o" ] || [ ! -d "$bundle" ]; then
    printf 'Run make verify before benchmarking.\n' >&2
    exit 1
fi

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
ln -s "$bundle" "$scratch/RightKitCore_RightKitCore.bundle"

xcrun swiftc -parse-as-library -O -I "$products" \
    scripts/perf/menu_benchmark.swift "$products/RightKitCore.o" \
    -o "$scratch/menu-benchmark"
xcrun swiftc -parse-as-library -O -I "$products" \
    RightKit/Engine/FileEngine.swift scripts/perf/transfer_benchmark.swift "$products/RightKitCore.o" \
    -o "$scratch/transfer-benchmark"

"$scratch/menu-benchmark"
"$scratch/transfer-benchmark" 10000
