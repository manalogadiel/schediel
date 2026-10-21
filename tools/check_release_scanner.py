"""Check the actual APK for ML Kit's reflectively created registrar constructors.

Run after the minified release build, not against debug JVM classes:
    python tools/check_release_scanner.py build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
Only APK code is inspected; this tool never reads images, OCR or app storage.
"""

import argparse
import re
import struct
import zipfile


REGISTRARS = {
    "com.google.mlkit.common.internal.CommonComponentRegistrar",
    "com.google.mlkit.vision.common.internal.VisionCommonRegistrar",
    "com.google.mlkit.vision.text.internal.TextRegistrar",
}


def public_constructors(data):
    if not data.startswith(b"dex\n"):
        raise ValueError("Expected a standard DEX file")

    def u32(at):
        return struct.unpack_from("<I", data, at)[0]

    def uleb(at):
        value = shift = 0
        for _ in range(5):
            byte = data[at]
            at += 1
            value |= (byte & 127) << shift
            if byte < 128:
                return value, at
            shift += 7
        raise ValueError("Invalid DEX integer")

    def string(index):
        at = u32(u32(60) + index * 4)
        _, at = uleb(at)
        return data[at:data.index(b"\0", at)].decode("utf-8", errors="replace")

    def type_name(index):
        return string(u32(u32(68) + index * 4))

    found = set()
    for i in range(u32(96)):
        at = u32(100) + i * 32
        descriptor = type_name(u32(at))
        name = descriptor[1:-1].replace("/", ".")
        if name not in REGISTRARS:
            continue
        cursor = u32(at + 24)
        if not cursor:
            continue
        counts = []
        for _ in range(4):
            count, cursor = uleb(cursor)
            counts.append(count)
        for _ in range(counts[0] + counts[1]):
            _, cursor = uleb(cursor)  # field index delta
            _, cursor = uleb(cursor)  # access flags
        method_index = 0
        for _ in range(counts[2]):  # direct methods include constructors
            delta, cursor = uleb(cursor)
            flags, cursor = uleb(cursor)
            _, cursor = uleb(cursor)
            method_index += delta
            method_at = u32(92) + method_index * 8
            proto_index = struct.unpack_from("<H", data, method_at + 2)[0]
            proto_at = u32(76) + proto_index * 12
            params = u32(proto_at + 8)
            if (string(u32(method_at + 4)) == "<init>" and flags & 1
                    and type_name(u32(proto_at + 4)) == "V"
                    and (params == 0 or u32(params) == 0)):
                found.add(name)
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk")
    args = parser.parse_args()
    found = set()
    with zipfile.ZipFile(args.apk) as apk:
        for entry in apk.namelist():
            if re.fullmatch(r"classes\d*\.dex", entry):
                found.update(public_constructors(apk.read(entry)))
    missing = REGISTRARS - found
    if missing:
        parser.exit(1, "FAIL: missing public no-argument scanner constructors:\n"
                    + "\n".join(sorted(missing)) + "\n")
    print("PASS: all 3 ML Kit registrar constructors survive in the release APK.")


if __name__ == "__main__":
    main()
