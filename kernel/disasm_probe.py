#!/usr/bin/env python3
"""Disassemble named functions from the SN512A GKI vmlinux.

Linear-sweeps each function with capstone, tracks the SP depth relative to
the syscall-entry frame, and reports every call site (bl/blr/b) plus
sp-relative accesses so stack-write geometry can be derived.
"""
import sys, re, bisect
from elftools.elf.elffile import ELFFile
from capstone import *

TEXT_VADDR = 0xffffffc008010000
TEXT_FOFF  = 0x20000
TEXT_END_V = 0xffffffc0097adb78   # .text end

VMLINUX = "vmlinux"
SYSMAP  = "System.map"


def load_syms():
    syms = {}
    order = []
    for line in open(SYSMAP):
        parts = line.split()
        if len(parts) < 3:
            continue
        try:
            a = int(parts[0], 16)
        except ValueError:
            continue
        name = parts[2]
        syms.setdefault(name, a)
        order.append((a, name))
    order.sort()
    return syms, order


SYMS, ORDER = load_syms()
ADDRS = [a for a, _ in ORDER]

def sym_at(addr):
    i = bisect.bisect_right(ADDRS, addr) - 1
    if i < 0:
        return None, 0
    return ORDER[i][1], ADDRS[i]

def func_end(addr):
    i = bisect.bisect_right(ADDRS, addr)
    while i < len(ORDER) and not ORDER[i][1]:
        i += 1
    return ADDRS[i] if i < len(ORDER) else addr + 0x400


def code_window(f, start, end):
    """yield (vaddr, bytes) chunks covering [start,end) inside .text"""
    buf = f.read()  # whole file once? too big; caller passes mmap
    raise NotImplementedError


def get_bytes(mm, start, end):
    """Return bytes for a vaddr range that lies in .text."""
    assert TEXT_VADDR <= start and end <= TEXT_END_V, hex(start)
    off = start - TEXT_VADDR + TEXT_FOFF
    return mm[off: off + (end - start)]


MD = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
MD.detail = True

def disasm_func(mm, name, extra_names=None, show_sp_writes=False,
                call_filter=None, annotate=False):
    start = SYMS[name]
    end = func_end(start)
    code = get_bytes(mm, start, end)
    insns = list(MD.disasm(code, start))
    print(f"== {name} @ {start:#x} .. {end:#x} ({len(insns)} insns) ==")
    # crude sp tracking: walk linearly, accumulate sub/add sp,sp,#imm
    # and stp/ldp pre/post-index on sp. Reset at basic-block boundaries
    # is overkill; prologue adjustments happen before first call anyway.
    sp = 0
    for idx, ins in enumerate(insns):
        mn = ins.mnemonic
        op = ins.op_str
        # track sp
        delta = None
        if re.match(r"^(sub|add)$", mn) and op.startswith("sp, sp, #"):
            imm = int(op.split("#")[1].split(",")[0].rstrip("]"), 0)
            if mn == "sub":
                sp -= imm
            else:
                sp += imm
            delta = imm
        elif mn == "stp" and "sp, #-" in op and op.endswith("]!"):
            imm = int(re.search(r"sp, #-(\d+|0x[0-9a-fA-F]+)", op).group(1), 0)
            sp -= imm
            delta = imm
        elif mn == "ldp" and "sp], #" in op:
            imm = int(op.rsplit("#", 1)[1].rstrip("!"), 0)
            sp += imm
            delta = imm
        tag = f"  [sp={sp:#x} d={delta:#x}]" if delta else (f"  [sp={sp:#x}]" if show_sp_writes else "")
        iscall = mn in ("bl", "b", "blr", "br")
        tgt = ""
        if mn in ("bl", "b") and op.startswith("#"):
            t = int(op[1:], 16)
            n, na = sym_at(t)
            tgt = f" -> {n}+{t - na:#x}" if n else f" -> {t:#x}"
            if n and t == na:
                tgt = f" -> {n}"
        elif mn in ("blr", "br"):
            tgt = " (indirect)"
        show = annotate or iscall or delta is not None or show_sp_writes
        if call_filter and iscall:
            t = int(op[1:], 16) if op.startswith("#") else None
            n, _ = sym_at(t) if t else (None, 0)
            if not call_filter(n):
                show = False
        if show:
            print(f"  {ins.address:#x}: {mn:8s} {op:60s}{tgt}{tag}")
    print()
    return insns


def main():
    f = open(VMLINUX, "rb")
    import mmap
    mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

    which = sys.argv[1] if len(sys.argv) > 1 else "all"

    if which in ("sched", "all"):
        # anchor 3: instruction after `bl __schedule` inside schedule()
        disasm_func(mm, "schedule", call_filter=lambda n: n == "__schedule")
        # anchor 1: ret after `bl schedule` in worker_thread
        disasm_func(mm, "worker_thread")
        # anchor 2: ret after `bl schedule` in wait_for_vfork_done
        disasm_func(mm, "wait_for_vfork_done")
        disasm_func(mm, "wait_for_common")

    if which in ("mcast", "all"):
        for n in ("__arm64_sys_setsockopt", "__sys_setsockopt",
                  "sock_common_setsockopt", "ipv6_setsockopt",
                  "do_ipv6_setsockopt"):
            disasm_func(mm, n)

    if which in ("futex", "all"):
        for n in ("__arm64_sys_futex", "do_futex", "futex_wait_requeue_pi"):
            disasm_func(mm, n)

    if which in ("sigret", "all"):
        for n in ("__arm64_sys_rt_sigreturn", "restore_sigframe",
                  "restore_sve_fpsimd_context"):
            disasm_func(mm, n, show_sp_writes=True)


if __name__ == "__main__":
    main()
