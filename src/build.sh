set -x

m68k-elf-as test.S

m68k-elf-objcopy -O verilog --verilog-data-width=4 a.out ../rtl/rom.mem
