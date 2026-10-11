#!/usr/bin/env python3
"""Minimal .BTF parser: dump member byte-offsets for named structs."""
import struct, sys
from elftools.elf.elffile import ELFFile

# BTF kinds (spec order)
K_INT, K_PTR, K_ARRAY, K_STRUCT, K_UNION, K_ENUM, K_FWD, K_TYPEDEF, \
K_VOLATILE, K_CONST, K_RESTRICT, K_FUNC, K_FUNC_PROTO, K_VAR, \
K_DATASEC, K_FLOAT, K_DECL_TAG, K_TYPE_TAG, K_ENUM64 = range(1, 20)


def parse_btf(buf):
    magic, ver, flags, hdr_len, type_off, type_len, str_off, str_len = \
        struct.unpack_from("<HBBIIIII", buf, 0)
    assert magic == 0xEB9F, hex(magic)
    types = buf[hdr_len + type_off: hdr_len + type_off + type_len]
    strs = buf[hdr_len + str_off: hdr_len + str_off + str_len]

    def name_at(o):
        e = strs.find(b"\0", o)
        return strs[o:e].decode("utf8", "replace")

    out = {}
    pos = 0
    while pos < len(types):
        n_off, info, size_t = struct.unpack_from("<III", types, pos)
        pos += 12
        kind = (info >> 24) & 0x1F
        vlen = info & 0xFFFF
        kflag = info & 0x80000000
        name = name_at(n_off)
        if kind in (K_STRUCT, K_UNION):
            mems = []
            for _ in range(vlen):
                mn, mtype, moff = struct.unpack_from("<III", types, pos)
                pos += 12
                boff = (moff & 0xFFFFFF) if kflag else moff
                mems.append((name_at(mn), boff // 8))
            if name:
                out.setdefault(name, {"size": size_t, "members": mems})
        elif kind == K_FUNC_PROTO:
            pos += vlen * 8
        elif kind == K_VAR:
            pos += 4
        elif kind == K_DATASEC:
            pos += vlen * 12
        elif kind == K_DECL_TAG:
            pos += 4
        elif kind in (K_ENUM, K_ENUM64):
            pos += vlen * 8
        # INT/PTR/TYPEDEF/VOLATILE/CONST/RESTRICT/FUNC/FWD/FLOAT/TYPE_TAG: no payload
    return out


def main():
    vmlinux = sys.argv[1] if len(sys.argv) > 1 else "vmlinux"
    elf = ELFFile(open(vmlinux, "rb"))
    data = elf.get_section_by_name(".BTF").data()
    structs = parse_btf(data)
    want = sys.argv[2:] or ["task_struct", "mm_struct", "cred",
                            "selinux_state", "rt_mutex_waiter",
                            "rt_mutex_base", "pipe_buffer"]
    for name in want:
        s = structs.get(name)
        if not s:
            print(f"{name}: NOT FOUND")
            continue
        print(f"struct {name} size=0x{s['size']:x}")
        for mn, off in s["members"]:
            print(f"  .{mn} = 0x{off:x}")


if __name__ == "__main__":
    main()
