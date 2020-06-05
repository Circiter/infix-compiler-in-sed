#!/bin/sed -Enf

# A [proof-of-concept] compiler for arithmetical expressions.
# Contains a implementation of recursive descent parsing
# and x86 machine code generation.

# (c) Circiter (mailto:xcirciter@gmail.com).
# Repository: https://github.com/Circiter/infix-compiler-in-sed
# License: MIT.

# Usage (for 32bit Linux):
#  echo <formula> | ./infix-compiler.x86.linux.sed > compiled.bin
#  m2elf.pl --in compiled.bin --out executable --mem=200 --binary
#  chmod +x executable
#  ./executable
# or:
#  ./test.sh <formula>

# See README.md for additional information.

# BNF grammar:
#
# expression ::= expression ; additive
#                additive
#
# additive ::= additive + multiplicative
#              additive - multiplicative
#
# multiplicative ::= multiplicative * unary
#                    multiplicative / unary
#
# unary ::= number
#           - unary
#           ( expression )

:read $!{N; bread}

s/$/@/

x
s/$/\xE8\x23\x00\x00\x00/ # Go to the entry point.

# String-to-integer conversion routine.
s/$/\x52\x31\xD2\xBE\x00\x01\x00\x00\xF7\xF6/
s/$/\x83\xEA\x30\x52\x93\xBE\x0A\x00\x00\x00\xF7\xE6\x93/
s/$/\x5A\x01\xD3\x83\xF8\x00\x75\xE2\x89\xD8\x5A\xC3/

# Entry point.
s/$/\x5A/
x
s/$/\nreturn_0/
bexpression; :return_0
x

# Show the minus sign for negative number.
s/$/\x83\xF8\x00\x7D\x1E\xF7\xD8/
s/$/\x50\xB8\x2d\x00\x00\x00\x50/
s/$/\x89\xE1\xBB\x01\x00\x00\x00/
s/$/\xB8\x04\x00\x00\x00\xBA\x01\x00\x00\x00/
s/$/\xCD\x80\x58\x58/

# Converting to decimal.
s/$/\x31\xC9\x41\x31\xD2/
s/$/\xBE\x0A\x00\x00\x00/
s/$/\xF7\xF6\x83\xC2\x30/
s/$/\x52\x83\xF8\x00\x75\xED/

# Printing.
s/$/\x49\x89\xE0\x51\x89\xC1/
s/$/\xBB\x01\x00\x00\x00/
s/$/\xB8\x04\x00\x00\x00/
s/$/\xBA\x01\x00\x00\x00/
s/$/\xCD\x80\x59\x58\x83\xF9\x00/
s/$/\x75\xE2/

s/$/\xB8\x01\x00\x00\x00\x31\xDB\xCD\x80/ # Exit.
x
bend

s/^[ ]*[^ ]//;

:expression
    s/$/\nreturn_1/
    badditive :return_1
    :while1
        /^;/! bend_expression
        s/^; *([^ ])/\1/ # NextToken
        s/$/\nreturn_2/
        badditive :return_2
        bwhile1
    :end_expression
    /return_7$/ {s/\n[^\n]*$//; breturn_7}
    /return_9$/ {s/\n[^\n]*$//; breturn_9}
    /return_0$/ {s/\n[^\n]*$//; breturn_0}
    bend

:additive
    s/$/\nreturn_3/
    bmultiplicative :return_3
    :while2
        /^\+/ {s/$/\n+/; bcontinue_while2}
        /^\-/ {s/$/\n-/; bcontinue_while2}
        bend_additive
        :continue_while2
        s/^[\+-] *([^ ])/\1/ # NextToken
        x; s/$/\x50/; x # push eax.
        s/$/\nreturn_4/
        bmultiplicative :return_4
        x; s/$/\x5B/; x # pop ebx.
        /\+$/ {s/\n\+$//; x; s/$/\x01\xD8/; x} # add eax, ebx.
        # xchg ebx, eax; sub eax, ebx.
        /\-$/ {s/\n\-$//; x; s/$/\x93\x29\xD8/; x}
        bwhile2
    :end_additive
    /return_1$/ {s/\n[^\n]*$//; breturn_1}
    /return_2$/ {s/\n[^\n]*$//; breturn_2}
    bend

:multiplicative
    s/$/\nreturn_5/
    bunary :return_5
    :while3
        /^\*/ {s/$/\n*/; bcontinue_while3}
        /^\// {s/$/\n\//; bcontinue_while3}
        /^%/ {s/$/\n%/; bcontinue_while3}
        bend_multiplicative
        :continue_while3
        s/^[\*\/%] *([^ ])/\1/ # NextToken
        x; s/$/\x50/; x # push eax.
        s/$/\nreturn_6/
        bunary :return_6
        x; s/$/\x5B/; x # pop ebx.
        /\*$/ {s/\n\*$//; x; s/$/\xF7\xEB/; x} # imul ebx.
        # xor edx, edx; idiv ebx.
        /\/$/ {s/\n\/$//; x; s/$/\x31\xD2\xF7\xFB/; x}
        # xor edx, edx; div ebx; xchg edx, eax
        /%$/ {s/\n%$//; x; s/$/\x31\xD2\xF7\xF3\x92/; x}
        bwhile3
    :end_multiplicative
    /return_3$/ {s/\n[^\n]*$//; breturn_3}
    /return_4$/ {s/\n[^\n]*$//; breturn_4}
    bend

# TODO: Add support for negative numbers.
:unary
    /^[0-9]+[^0-9]/ {
        x; s/$/\x31\xDB@/; G # xor ebx, ebx
        s/@\n([0-9]+)[^0-9].*$/@\1/ # Append the value as a string.
        :store_string
            s/@/\xB8@/ # mov eax, <value>.
            :padding /@..../! s/@.*$/&\x00/; tpadding
            s/@(....)/\1\xFF\xD2@/ # call edx.
            /@./ bstore_string
        s/@//; x
        s/^[0-9]+([^0-9])/\1/
        #s/^0x....//
        bend_unary
    }

    /^\(/ {
        s/^\(//
        s/$/\nreturn_7/
        bexpression :return_7
        s/^ *\) *//
        bend_unary
    }

    /^-/ {
        s/^-//
        s/$/\nreturn_8/
        bunary :return_8
        x; s/$/\xF7\xD8/; x # neg eax.
        bend_unary
    }

    s/$/\nreturn_9/
    bexpression :return_9

    :end_unary
    /return_5$/ {s/\n[^\n]*$//; breturn_5}
    /return_6$/ {s/\n[^\n]*$//; breturn_6}
    /return_8$/ {s/\n[^\n]*$//; breturn_8}
    bend

:end x; p; q
