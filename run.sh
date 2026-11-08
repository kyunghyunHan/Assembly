#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ $# -ne 1 ]]; then
  echo "Usage: ./run.sh <lesson-source.s>" >&2
  echo "Example: ./run.sh 16-fault-investigation.s" >&2
  exit 2
fi

source_name=$1
case "$source_name" in
  [0-9][0-9]-*.s) ;;
  *)
    echo "Expected a lesson source such as 16-fault-investigation.s" >&2
    exit 2
    ;;
esac

source_file="src/$source_name"
if [[ ! -f "$source_file" ]]; then
  echo "Lesson source not found: $source_file" >&2
  exit 2
fi

lesson=${source_name%.s}
build_dir="build/$lesson"
mkdir -p "$build_dir"

arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c "$source_file" -o "$build_dir/main.o"
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -nostdlib -T linker.ld \
  -Wl,-Map="$build_dir/main.map" "$build_dir/main.o" -o "$build_dir/main.elf"
arm-none-eabi-objcopy -O binary "$build_dir/main.elf" "$build_dir/main.bin"
qemu-system-arm -M mps2-an386 -nographic -semihosting -kernel "$build_dir/main.elf"
