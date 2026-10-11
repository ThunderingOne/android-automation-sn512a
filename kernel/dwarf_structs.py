#!/usr/bin/env python3
"""Targeted DWARF member-offset query for SN512A vmlinux.

Scans CU top-level DIEs for the named structs; stops as soon as every
struct has been found with full members (task_struct/mm_struct appear in
nearly every CU, so this exits quickly).
"""
import sys, time
from elftools.elf.elffile import ELFFile

FIELDS = {
    "task_struct": ["thread_info", "state", "stack", "usage", "prio",
                    "static_prio", "normal_prio", "rt_priority",
                    "sched_task_group", "pid", "tgid", "real_parent",
                    "atomic_flags", "cred", "real_cred", "comm", "tasks",
                    "mm", "pi_lock", "pi_waiters", "pi_top_task",
                    "pi_blocked_on", "seccomp", "thread"],
    "mm_struct": ["owner", "mm_mt", "mmap", "pgd"],
    "task_group": ["se"],
    "rt_mutex_waiter": ["tree_entry", "pi_tree_entry", "task", "lock",
                        "wake_state", "prio", "deadline"],
    "rb_root": ["rb_node"],
    "seccomp": ["mode", "filter"],
}

MAX_CUS = 400

def member_offsets(die, wanted):
    out = {}
    for m in die.iter_children():
        if m.tag != "DW_TAG_member":
            continue
        nm = m.attributes.get("DW_AT_name")
        if not nm:
            continue
        name = nm.value.decode()
        if name not in wanted or name in out:
            continue
        loc = m.attributes.get("DW_AT_data_member_location")
        if loc is None:
            continue
        v = loc.value
        if isinstance(v, list):
            # exprloc: usually DW_OP_plus_uconst -> last byte is uconst
            try:
                from elftools.dwarf.dwarf_expr import describe_DWARF_expr
                desc = describe_DWARF_expr(v, die.dwarfinfo.structs)
                off = int(desc.split()[-1])
            except Exception:
                off = v[-1]
            v = off
        out[name] = v
    return out

def main():
    f = open("vmlinux", "rb")
    elf = ELFFile(f)
    dwarf = elf.get_dwarf_info()
    wanted = dict(FIELDS)
    got = {}
    t0 = time.time()
    for i, cu in enumerate(dwarf.iter_CUs()):
        if not wanted or i > MAX_CUS:
            break
        try:
            top = cu.get_top_DIE()
            for die in top.iter_children():
                if die.tag not in ("DW_TAG_structure_type",
                                   "DW_TAG_class_type"):
                    continue
                nm = die.attributes.get("DW_AT_name")
                if not nm:
                    continue
                name = nm.value.decode()
                if name not in wanted or name in got:
                    continue
                sz = die.attributes.get("DW_AT_byte_size")
                # skip incomplete decls (no byte_size or no members)
                if sz is None:
                    continue
                offs = member_offsets(die, wanted[name])
                if not offs:
                    continue
                got[name] = (sz.value, offs)
                print(f"# found {name} in CU {i} "
                      f"({time.time()-t0:.1f}s) size=0x{sz.value:x}")
                if all(k in got for k in wanted):
                    wanted = {}
                    break
        except Exception as e:
            print(f"# CU {i} error {e}")
    print(f"# scan done {time.time()-t0:.1f}s")
    for sname, fields in FIELDS.items():
        g = got.get(sname)
        if not g:
            print(f"{sname}: NOT FOUND")
            continue
        sz, offs = g
        print(f"{sname} size=0x{sz:x}")
        for fld in fields:
            print(f"  .{fld:20s} = {offs.get(fld)}")

if __name__ == "__main__":
    main()
