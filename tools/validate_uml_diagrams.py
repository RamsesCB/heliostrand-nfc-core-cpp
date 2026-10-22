#!/usr/bin/env python3
"""Check editable Draw.io routes for node intersections without third-party modules."""
from __future__ import annotations

import argparse
import math
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

EXPECTED_EDGES = (15, 20, 10, 11, 18, 22)
IGNORED = {
    "title_banner", "m_title_banner", "jd_uc_title", "ma_uc_title",
    "jd_proc_title", "ma_proc_title", "jd_sys_boundary", "ma_sys_boundary",
}


def rectangles(diagram):
    cells = {cell.get("id"): cell for cell in diagram.findall(".//mxCell")}
    cache = {}

    def locate(cell):
        cid = cell.get("id")
        if cid in cache:
            return cache[cid]
        geo = cell.find("mxGeometry")
        box = [float(geo.get(key, 0)) for key in ("x", "y", "width", "height")]
        parent = cells.get(cell.get("parent"))
        if parent is not None and parent.get("vertex") == "1":
            x, y, _, _ = locate(parent)
            box[0] += x
            box[1] += y
        cache[cid] = tuple(box)
        return cache[cid]

    result = {
        cid: locate(cell)
        for cid, cell in cells.items()
        if cell.get("vertex") == "1"
        and cid not in IGNORED
        and not cid.startswith("lane_")
    }
    return result


def segment_intersects(a, b, rect, inset=4):
    x, y, w, h = rect
    x += inset
    y += inset
    w -= inset * 2
    h -= inset * 2
    if w <= 0 or h <= 0:
        return False
    dx, dy = b[0] - a[0], b[1] - a[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, a[0] - x), (dx, x + w - a[0]),
                 (-dy, a[1] - y), (dy, y + h - a[1])):
        if abs(p) < 1e-9:
            if q < 0:
                return False
        else:
            t = q / p
            if p < 0:
                t0 = max(t0, t)
            else:
                t1 = min(t1, t)
            if t0 > t1:
                return False
    return True


def endpoints(edge, nodes):
    style = {}
    for entry in edge.get("style", "").split(";"):
        if "=" in entry:
            key, value = entry.split("=", 1)
            style[key] = value
    for field in ("exitX", "exitY", "entryX", "entryY"):
        if field not in style:
            raise ValueError(f"missing anchor {field}")
    sx, sy, sw, sh = nodes[edge.get("source")]
    tx, ty, tw, th = nodes[edge.get("target")]
    start = (sx + float(style["exitX"]) * sw,
             sy + float(style["exitY"]) * sh)
    end = (tx + float(style["entryX"]) * tw,
           ty + float(style["entryY"]) * th)
    points = [
        (float(pt.get("x")), float(pt.get("y")))
        for pt in edge.findall("./mxGeometry/Array[@as='points']/mxPoint")
    ]
    return [start, *points, end]


def check(path):
    diagrams = ET.parse(path).getroot().findall(".//diagram")
    if len(diagrams) != 6:
        raise ValueError(f"expected six diagrams, found {len(diagrams)}")
    total = 0
    for index, diagram in enumerate(diagrams):
        nodes = rectangles(diagram)
        edges = diagram.findall(".//mxCell[@edge='1']")
        if len(edges) != EXPECTED_EDGES[index]:
            raise ValueError(f"page {index + 1}: expected {EXPECTED_EDGES[index]} edges, got {len(edges)}")
        for edge in edges:
            src = edge.get("source")
            dst = edge.get("target")
            eid = edge.get("id")
            if src not in nodes or dst not in nodes:
                raise ValueError(f"{eid}: missing source/target")
            path_points = endpoints(edge, nodes)
            for a, b in zip(path_points, path_points[1:]):
                if abs(a[0] - b[0]) > 0.15 and abs(a[1] - b[1]) > 0.15:
                    raise ValueError(f"{eid}: diagonal segment {a} to {b}")
                for nid, rect in nodes.items():
                    if nid not in (src, dst) and segment_intersects(a, b, rect):
                        raise ValueError(f"{eid}: route enters unrelated node {nid}")
        print(f"OK {index + 1}/6: {diagram.get('name')} — {len(edges)} connections")
        total += len(edges)
    print(f"PASS — {total} orthogonal links, no unrelated node intersections")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "file", nargs="?",
        default="docs/diagrams/Heliostrand_Diagramas_Completos.drawio",
        help="path to the unified editable .drawio file",
    )
    args = parser.parse_args()
    try:
        check(Path(args.file))
    except (ET.ParseError, ValueError, OSError, KeyError) as error:
        print(f"FAIL — {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
