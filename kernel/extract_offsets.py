#!/usr/bin/env python3
"""Extract GhostLock kernel_offsets for SN512A from GKI vmlinux.

Outputs a target.h-ready OFFSETS_ENTRY for kernel
5.15.197-android13-8-00005-g2d8ad9139b89 (GKI android13-5.15-2026-03_r2,
CI build 15063902).
"""
import sys
from elftools.elf.elffile import ELFFile
from elftools.dwarf.dwarfinfo import DWARFInfo

VMLINUX = "vmlinux"

# Symbols needed by ghostlock-emerald kernel_offsets
SYMS = [
    "init_task", "init_cred", "init_uts_ns", "empty_zero_page",
    "root_task_group", "selinux_enforcing", "kptr_restrict",
    "selinux_blob_sizes", "kmalloc_caches", "anon_pipe_buf_ops",
    "ashmem_misc_fops", "ashmem_fops", "ashmem_ioctl",
    "ashmem_compat_ioctl", "ashmem_mmap", "ashmem_open",
    "ashmem_release", "ashmem_show_fdinfo", "configfs_read_iter",
    "configfs_bin_write_iter", "copy_splice_read",
    "generic_file_splice_read", "noop_llseek",
    "system_unbound_wq", "call_usermodehelper_exec_work",
    # slide anchors
    "nfulnl_logger", "boot_id", "sysctl_bootid",
]

# Struct members for STRUCT_OFFSETS_5_15
STRUCT_FIELDS = {
    "task_struct": ["prio", "normal_prio", "sched_task_group", "pi_lock",
                    "pi_waiters", "pi_top_task", "pi_blocked_on", "pid",
                    "tgid", "real_parent", "atomic_flags", "real_cred",
                    "cred", "comm", "tasks", "seccomp"],
    "mm_struct": ["owner"],
    "selinux_state": ["enforcing", "initialized"],
    "cred": ["uid", "gid", "suid", "sgid", "euid", "egid", "fsuid", "fsgid",
             "cap_inheritable", "cap_permitted", "cap_effective",
             "cap_bset", "cap_ambient", "securebits", "user_ns",
             "ucounts", "group_info"],
}


def member_offset(struct_type, name):
    """Return byte offset of member `name` in DWARF struct `struct_type`."""
    try:
        for m in struct_type.iter_members():
            if m.name and m.name.decode() == name:
                loc = m.attributes.get("DW_AT_data_member_location")
                if loc is None:
                    return None
                v = loc.value
                if isinstance(v, list):  # exprloc -> OP_plus_uconst
                    return v[-1]
                return v
    except Exception:
        pass
    return None


def main():
    f = open(VMLINUX, "rb")
    elf = ELFFile(f)

    # --- symbols from symtab (authoritative) ---
    symtab = elf.get_section_by_name(".symtab")
    found = {}
    for s in symtab.iter_symbols():
        n = s.name
        if n in SYMS:
            found[n] = s.entry.st_value
    for n in SYMS:
        v = found.get(n)
        print(f"SYM {n:35s} {'0x%012x' % v if v else 'MISSING'}")

    # --- DWARF struct offsets ---
    print()
    dwarf = elf.get_dwarf_info()
    wanted = set(STRUCT_FIELDS)
    got = {}
    for cu in dwarf.iter_CUs():
        top = cu.get_top_DIE()
        for die in top.iter_children():
            nm = die.attributes.get("DW_AT_name")
            if die.tag == "DW_TAG_structure_type" and nm:
                name = nm.value.decode()
                if name in wanted and name not in got:
                    got[name] = die
    for sname, fields in STRUCT_FIELDS.items():
        die = got.get(sname)
        if not die:
            print(f"STRUCT {sname}: NOT FOUND")
            continue
        for fld in fields:
            off = member_offset(die, fld)
            print(f"FLD {sname}.{fld:22s} {'0x%x' % off if off is not None else 'MISSING'}")


if __name__ == "__main__":
    main()
