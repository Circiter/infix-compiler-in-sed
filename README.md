# infix-compiler-in-sed

An implementation of recursive descent parsing and [machine] code generation in sed
(the famous stream text editor).

Accepts an infix arithmetic formula (e.g, `(1+2)*3`) and produces a x86 machine code (without
headers), which in turn can be "linked" by the script m2elf.pl to become an actual elf32
executable file for Linux (in theory it is possible to get rid of the dependency on the m2elf.pl
but it's not so easy).

Being run, this executable just evaluates the aforementioned
arithmetic expression and prints the result (one decimal number), e.g. for formula `(1+2)*3`
it will print `9`. N.B., the executable program does not interpret the textual representation
of an expression, instead the sed script generates a true machine code. That is, it is a
true, although inefficient, compiler!

Usage (for 32bit Linux):

```sh
echo <formula> | ./infix-compiler.x86.linux.sed > compiled.bin
m2elf.pl --in compiled.bin --out executable --binary
chmod +x executable
./executable
```

or:

```sh
./test.sh <formula>
```

Dependencies:
- x86 CPU (32 bit PC-compatible machine),
- 32 bit Linux,
- GNU sed,
- [m2elf.pl](https://github.com/XlogicX/m2elf),
- Perl (for m2elf.pl),
- Optional: xxd, objdump (used by test.sh),
- Optional: qemu (or its analog), if you lack a Linux/x86 box.

Actual code is contained in `infix-compiler.x86.linux.sed`, have a look.

You can use `objdump` or `ndisasm` to disassemble a generated code, but I think
it'll be useful to provide a commented example listing for some simple formula,
like `1+2`; So I placed the file `commented-example.asm` in the repository. It's
written in Intel-style assembler for [nasm](https://sourceforge.net/projects/nasm).

# (c) Circiter, mailto:xcirciter@gmail.com
# MIT license.
