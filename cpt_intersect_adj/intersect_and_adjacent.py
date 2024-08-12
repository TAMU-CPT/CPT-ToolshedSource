#!/usr/bin/env python
import logging
import argparse
from intervaltree import IntervalTree, Interval
from CPT_GFFParser import gffParse, gffWrite
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


def validFeat(rec):
    for feat in rec.features:
        if feat.type != "remark" and feat.type != "annotation":
            return True
    return False


def treeFeatures(features, window):
    for feat in features:
        # Interval(begin, end, data)
        yield Interval(
            int(feat.location.start) - int(window),
            int(feat.location.end) + int(window),
            feat.id,
        )


def treeFeatures_noRem(features, window):
    for feat in features:
        if feat.type == "remark" or feat.type == "annotation":
            continue
        # Interval(begin, end, data)
        yield Interval(
            int(feat.location.start) - int(window),
            int(feat.location.end) + int(window),
            feat.id,
        )


def intersect(a, b, window, stranding):
    rec_a = list(gffParse(a))
    rec_b = list(gffParse(b))
    rec_a_out = []
    rec_b_out = []
    maxLen = min(len(rec_a), len(rec_b))
    iterate = 0

    if maxLen > 0:
        while iterate < maxLen:
            rec_a_i = rec_a[iterate]
            rec_b_i = rec_b[iterate]

            if (not validFeat(rec_a_i)) or (not validFeat(rec_b_i)):
                rec_a_out.append(
                    SeqRecord(
                        rec_a[iterate].seq,
                        rec_a[iterate].id,
                        rec_a[iterate].name,
                        rec_a[iterate].description,
                        rec_a[iterate].dbxrefs,
                        [],
                        rec_a[iterate].annotations,
                    )
                )
                rec_b_out.append(
                    SeqRecord(
                        rec_b[iterate].seq,
                        rec_b[iterate].id,
                        rec_b[iterate].name,
                        rec_b[iterate].description,
                        rec_b[iterate].dbxrefs,
                        [],
                        rec_b[iterate].annotations,
                    )
                )
                iterate += 1
                continue

            a_neg = []
            a_pos = []
            b_neg = []
            b_pos = []
            tree_a = []
            tree_b = []

            for feat in rec_a_i.features:
                if feat.type == "remark" or feat.type == "annotation":
                    continue
                interval = Interval(
                    int(feat.location.start) - int(window),
                    int(feat.location.end) + int(window),
                    feat.id,
                )
                if stranding:
                    if feat.strand > 0:
                        a_pos.append(interval)
                    else:
                        a_neg.append(interval)
                else:
                    tree_a.append(interval)

            for feat in rec_b_i.features:
                if feat.type == "remark" or feat.type == "annotation":
                    continue
                interval = Interval(
                    int(feat.location.start) - int(window),
                    int(feat.location.end) + int(window),
                    feat.id,
                )
                if stranding:
                    if feat.strand > 0:
                        b_pos.append(interval)
                    else:
                        b_neg.append(interval)
                else:
                    tree_b.append(interval)

            if stranding:
                tree_a_pos = IntervalTree(a_pos)
                tree_a_neg = IntervalTree(a_neg)
                tree_b_pos = IntervalTree(b_pos)
                tree_b_neg = IntervalTree(b_neg)
            else:
                tree_a = IntervalTree(tree_a)
                tree_b = IntervalTree(tree_b)

            # Used to map ids back to features later
            rec_a_map = {f.id: f for f in rec_a_i.features}
            rec_b_map = {f.id: f for f in rec_b_i.features}

            rec_a_hits_in_b = {}
            rec_b_hits_in_a = {}

            for feature in rec_a_i.features:
                if feature.type == "remark" or feature.type == "annotation":
                    continue

                if not stranding:
                    hits = tree_b[
                        int(feature.location.start) : int(feature.location.end)
                    ]
                    for hit in hits:
                        rec_a_hits_in_b[hit.data] = rec_b_map[hit.data]
                else:
                    if feature.strand > 0:
                        hits = tree_b_pos[
                            int(feature.location.start) : int(feature.location.end)
                        ]
                    else:
                        hits = tree_b_neg[
                            int(feature.location.start) : int(feature.location.end)
                        ]
                    for hit in hits:
                        rec_a_hits_in_b[hit.data] = rec_b_map[hit.data]

            for feature in rec_b_i.features:
                if feature.type == "remark" or feature.type == "annotation":
                    continue

                if not stranding:
                    hits = tree_a[
                        int(feature.location.start) : int(feature.location.end)
                    ]
                    for hit in hits:
                        rec_b_hits_in_a[hit.data] = rec_a_map[hit.data]
                else:
                    if feature.strand > 0:
                        hits = tree_a_pos[
                            int(feature.location.start) : int(feature.location.end)
                        ]
                    else:
                        hits = tree_a_neg[
                            int(feature.location.start) : int(feature.location.end)
                        ]
                    for hit in hits:
                        rec_b_hits_in_a[hit.data] = rec_a_map[hit.data]

            # Sort features by start position
            rec_a_out.append(
                SeqRecord(
                    rec_a[iterate].seq,
                    rec_a[iterate].id,
                    rec_a[iterate].name,
                    rec_a[iterate].description,
                    rec_a[iterate].dbxrefs,
                    sorted(
                        rec_a_hits_in_b.values(), key=lambda feat: feat.location.start
                    ),
                    rec_a[iterate].annotations,
                )
            )
            rec_b_out.append(
                SeqRecord(
                    rec_b[iterate].seq,
                    rec_b[iterate].id,
                    rec_b[iterate].name,
                    rec_b[iterate].description,
                    rec_b[iterate].dbxrefs,
                    sorted(
                        rec_b_hits_in_a.values(), key=lambda feat: feat.location.start
                    ),
                    rec_b[iterate].annotations,
                )
            )
            iterate += 1

    else:
        # If one input is empty, output two empty result files.
        rec_a_out = [SeqRecord(Seq(""), "none")]
        rec_b_out = [SeqRecord(Seq(""), "none")]
    return rec_a_out, rec_b_out


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="rebase gff3 features against parent locations", epilog=""
    )
    parser.add_argument("a", type=argparse.FileType("r"))
    parser.add_argument("b", type=argparse.FileType("r"))
    parser.add_argument(
        "window",
        type=int,
        default=50,
        help="Allows features this far away to still be considered 'adjacent'",
    )
    parser.add_argument(
        "-stranding",
        action="store_true",
        help="Only allow adjacency for same-strand features",
    )
    parser.add_argument("--oa", type=str, default="a_hits_near_b.gff")
    parser.add_argument("--ob", type=str, default="b_hits_near_a.gff")
    args = parser.parse_args()

    b, a = intersect(args.a, args.b, args.window, args.stranding)

    with open(args.oa, "w") as handle:
        for rec in a:
            gffWrite([rec], handle)

    with open(args.ob, "w") as handle:
        for rec in b:
            gffWrite([rec], handle)
