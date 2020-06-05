#!/bin/sh

if [ "x$1" = x ]; then
    echo usage: $0 '<formula>'
    exit
fi

echo "$1" | ./infix-compiler.x86.linux.sed > compiled.bin
echo machine code:
cat compiled.bin | xxd
./m2elf.pl --in compiled.bin --out compiled --mem=200 --binary
chmod +x compiled
echo compiled.
echo disassembling:
objdump --show-raw-insn --disassemble --architecture=i386 --disassembler-options=intel,intel-mnemonic compiled 2>&1
echo executing:
./compiled
