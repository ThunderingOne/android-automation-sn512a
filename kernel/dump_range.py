#!/usr/bin/env python3
import sys, bisect
from elftools.elf.elffile import ELFFile
from capstone import *

TEXT_VADDR = 0xffffffc008010000
TEXT_FOFF  = 0x20000
TEXT_END_V = 0xffffffc0097adb78

syms = {}
order = []
for line in open("System.map"):
    p = line.split()
    if len(p) < 3: continue
    try: a = int(p[0], 16)
    except ValueError: continue
    syms.setdefault(p[2], a); order.append((a, p[2]))
order.sort(); ADDRS = [a for a,_ in order]
ORDER = order

def sym_at(addr):
    i = bisect.bisect_right(ADDRS, addr) - 1
    return (ORDER[i][1], ADDRS[i]) if i >= 0 else (None, 0)

f = open("vmlinux","rb")
import mmap; mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

MD = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)

def dump(start, end):
    code = mm[start - TEXT_VADDR + TEXT_FOFF : end - TEXT_VADDR + TEXT_FOFF]
    for ins in MD.disasm(code, start):
        tgt = ""
        if ins.mnemonic in ("bl","b","adrp","adr","cbz","cbnz","tbz","tbnz",
                            "b.eq","b.ne","b.hi","b.lo","b.cc","b.cs","b.ge",
                            "b.lt","b.gt","b.le","b.mi","b.pl","b.vs","b.vc",
                            "b.al","b.nv","csel","cset") and ins.op_str.startswith("#"):
            t = int(ins.op_str[1:], 16)
            n, na = sym_at(t)
            if n: tgt = f"    -> {n}+{t-na:#x}" if t != na else f"    -> {n}"
        print(f"  {ins.address:#x}: {ins.mnemonic:8s} {ins.op_str}{tgt}")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        dump(int(sys.argv[1], 16), int(sys.argv[2], 16))
    else:
        name = sys.argv[1]
        start = syms[name]
        i = bisect.bisect_right(ADDRS, start)
        end = ADDRS[i]
        if len(sys.argv) > 2:
            start += int(sys.argv[2], 0)
            end = min(end, start + (int(sys.argv[3], 0) if len(sys.argv)>3 else 0x200))
        dump(start, end)
