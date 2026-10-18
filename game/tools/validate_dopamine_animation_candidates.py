#!/usr/bin/env python3
"""Validate staged sprite-sheet geometry, palette, hashes and frame identity."""

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "docs/art/palette_master.gpl"


def decode_png(path: Path) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    data = path.read_bytes()
    assert data.startswith(b"\x89PNG\r\n\x1a\n"), f"invalid PNG: {path}"
    width = height = color_type = bit_depth = None
    palette: list[tuple[int, int, int, int]] = []
    transparency = b""
    compressed = bytearray()
    offset = 8
    while offset < len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        tag, payload = data[offset + 4:offset + 8], data[offset + 8:offset + 8 + length]
        if tag == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
            assert bit_depth == 8 and color_type in (3, 6) and interlace == 0, f"unsupported PNG: {path}"
        elif tag == b"PLTE":
            palette = [tuple(payload[i:i + 3]) + (255,) for i in range(0, len(payload), 3)]
        elif tag == b"tRNS":
            transparency = payload
        elif tag == b"IDAT":
            compressed.extend(payload)
        elif tag == b"IEND":
            break
        offset += length + 12
    assert width and height
    bpp = 1 if color_type == 3 else 4
    stride = width * bpp
    raw = zlib.decompress(compressed)
    rows: list[bytearray] = []
    pos = 0
    for _ in range(height):
        kind = raw[pos]
        encoded = raw[pos + 1:pos + 1 + stride]
        pos += stride + 1
        row = bytearray(stride)
        above = rows[-1] if rows else bytearray(stride)
        for i, value in enumerate(encoded):
            left = row[i - bpp] if i >= bpp else 0
            up = above[i]
            upper_left = above[i - bpp] if i >= bpp else 0
            if kind == 0: predictor = 0
            elif kind == 1: predictor = left
            elif kind == 2: predictor = up
            elif kind == 3: predictor = (left + up) // 2
            elif kind == 4:
                p = left + up - upper_left
                distances = (abs(p - left), abs(p - up), abs(p - upper_left))
                predictor = (left, up, upper_left)[distances.index(min(distances))]
            else: raise AssertionError(f"unsupported PNG filter {kind}: {path}")
            row[i] = (value + predictor) & 255
        rows.append(row)
    pixels = []
    if color_type == 3:
        for row in rows:
            for index in row:
                rgb = palette[index]
                alpha = transparency[index] if index < len(transparency) else 255
                pixels.append(rgb[:3] + (alpha,))
    else:
        pixels = [tuple(row[i:i + 4]) for row in rows for i in range(0, stride, 4)]
    return width, height, pixels


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    approved = set()
    for line in PALETTE_PATH.read_text().splitlines():
        fields = line.split()
        if len(fields) >= 4 and all(value.isdigit() for value in fields[:3]):
            approved.add(tuple(map(int, fields[:3])) + (255,))
    report = {"status": "passed", "root": str(args.root.resolve()), "animations": []}
    metadata_paths = [p for p in args.root.rglob("*.json") if p.name != "qa-report.json"]
    for metadata_path in sorted(metadata_paths):
        metadata = json.loads(metadata_path.read_text())
        if "grid" not in metadata:
            continue
        image_path = metadata_path.with_suffix(".png")
        source_path = args.root / metadata["source_path"]
        width, height, pixels = decode_png(image_path)
        frame_width, frame_height = metadata["frame_size"]
        columns, rows = metadata["grid"]
        assert (width, height) == (frame_width * columns, frame_height * rows), f"sheet dimensions mismatch: {image_path}"
        assert {pixel for pixel in pixels if pixel[3]} <= approved, f"palette violation: {image_path}"
        frame_records = []
        for row in range(rows):
            hashes = set()
            for column in range(columns):
                colors, visible, frame_values = set(), [], bytearray()
                for y in range(row * frame_height, (row + 1) * frame_height):
                    for x in range(column * frame_width, (column + 1) * frame_width):
                        pixel = pixels[y * width + x]
                        frame_values.extend(pixel)
                        if pixel[3]:
                            colors.add(pixel)
                            visible.append((x - column * frame_width, y - row * frame_height))
                assert visible, f"empty animation frame ({row},{column}): {image_path}"
                assert len(colors) <= 16 if (frame_width, frame_height) == (32, 32) else len(colors) <= 32, \
                    f"frame color limit exceeded ({row},{column}): {image_path}"
                xs, ys = zip(*visible)
                bounds = [min(xs), min(ys), max(xs), max(ys)]
                frame_hash = hashlib.sha256(frame_values).hexdigest()
                assert frame_hash not in hashes, f"duplicate frame in direction row {row}: {image_path}"
                hashes.add(frame_hash)
                frame_records.append({"direction_row": row, "column": column, "colors": len(colors), "bounds": bounds})
        assert source_path.read_bytes()[4:6] == struct.pack("<H", 0xA5E0), f"invalid Aseprite source: {source_path}"
        assert hashlib.sha256(source_path.read_bytes()).hexdigest() == metadata["source_sha256"], f"source hash mismatch: {source_path}"
        assert hashlib.sha256(image_path.read_bytes()).hexdigest() == metadata["export_sha256"], f"export hash mismatch: {image_path}"
        report["animations"].append({"asset_id": metadata["asset_id"], "dimensions": [width, height],
                                     "grid": [columns, rows], "frames": frame_records,
                                     "source": str(source_path), "export": str(image_path)})
    assert report["animations"], "no animation metadata found"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
