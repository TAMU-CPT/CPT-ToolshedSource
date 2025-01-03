import argparse
from cpt import OrfFinder
from spaninFuncs import *
import re

"""
##  Note
NOTE : This was made after I made the i-spanin and o-spanin tools, so there might be some methods that are used differently
and overall some 'differently' written code...
"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Get putative protein candidates for u-spanins"
    )

    parser.add_argument(
        "fasta_file", type=argparse.FileType("r"), help="Fasta file"
    )  # the "input" argument

    parser.add_argument(
        "--strand",
        dest="strand",
        choices=("both", "forward", "reverse"),
        default="both",
        help="select strand",
    )  # Selection of +, -, or both strands

    parser.add_argument(
        "--table", dest="table", default=11, help="NCBI Translation table", type=int
    )  # Uses "default" NCBI codon table. This should always (afaik) be what we want...

    parser.add_argument(
        "-t",
        "--ftype",
        dest="ftype",
        choices=("CDS", "ORF"),
        default="ORF",
        help="Find ORF or CDSs",
    )  # "functional type(?)" --> Finds ORF or CDS, for this we want just the ORF

    parser.add_argument(
        "-e",
        "--ends",
        dest="ends",
        choices=("open", "closed"),
        default="closed",
        help="Open or closed. Closed ensures start/stop codons are present",
    )  # includes the start and stop codon

    parser.add_argument(
        "-m",
        "--mode",
        dest="mode",
        choices=("all", "top", "one"),
        default="all",  # I think we want this to JUST be all...nearly always
        help="Output all ORFs/CDSs from sequence, all ORFs/CDSs with max length, or first with maximum length",
    )

    parser.add_argument(
        "--switch",
        dest="switch",
        default="all",
        help="switch between ALL putative usps, or a range. If not all, insert a range of two integers separated by a colon (:). Eg: 1234:4321",
    )

    parser.add_argument(
        "--usp_on",
        dest="out_usp_nuc",
        type=argparse.FileType("w"),
        default="_out_usp.fna",
        help="Output nucleotide sequences, FASTA",
    )
    parser.add_argument(
        "--usp_op",
        dest="out_usp_prot",
        type=argparse.FileType("w"),
        default="_out_usp.fa",
        help="Output protein sequences, FASTA",
    )
    parser.add_argument(
        "--usp_ob",
        dest="out_usp_bed",
        type=argparse.FileType("w"),
        default="_out_usp.bed",
        help="Output BED file",
    )
    parser.add_argument(
        "--usp_og",
        dest="out_usp_gff3",
        type=argparse.FileType("w"),
        default="_out_usp.gff3",
        help="Output GFF3 file",
    )
    parser.add_argument(
        "--putative_usp",
        dest="putative_usp_fa",
        type=argparse.FileType("w"),
        default="_putative_usp.fa",
        help="Output of putative FASTA file",
    )
    parser.add_argument(
        "--summary_usp_txt",
        dest="summary_usp_txt",
        type=argparse.FileType("w"),
        default="_summary_usp.txt",
        help="Summary statistics on putative o-spanins",
    )
    parser.add_argument(
        "--putative_usp_gff",
        dest="putative_usp_gff",
        type=argparse.FileType("w"),
        default="_putative_usp.gff3",
        help="gff3 output for putative o-spanins",
    )

    parser.add_argument(
        "--min_size", type=int, default=100, help="minimum size of peptide"
    )
    parser.add_argument(
        "--max_size", type=int, default=200, help="maximum size of peptide"
    )
    parser.add_argument(
        "--lipo_min_start", type=int, default=10, help="minimum start site of lipobox"
    )
    parser.add_argument(
        "--lipo_max_start", type=int, default=30, help="maximum end site of lipobox"
    )
    parser.add_argument(
        "--min_lipo_after",
        type=int,
        default=60,
        help="minumum amount of residues after lipobox",
    )
    parser.add_argument(
        "--max_lipo_after",
        type=int,
        default=160,
        help="maximum amount of residues after lipobox",
    )
    parser.add_argument(
        "--tmd_min_start", type=int, default=75, help="minumum start site of TMD"
    )
    parser.add_argument(
        "--tmd_max_start", type=int, default=200, help="maximum end site of TMD"
    )
    parser.add_argument(
        "--tmd_min_size", type=int, default=15, help="minimum size of TMD"
    )
    parser.add_argument(
        "--tmd_max_size", type=int, default=25, help="maximum size of TMD"
    )

    args = parser.parse_args()

    the_args = vars(parser.parse_args())

    ### usp output, naive ORF finding:
    usps = OrfFinder(args.table, args.ftype, args.ends, args.min_size, args.strand)
    usps.locate(
        args.fasta_file,
        args.out_usp_nuc,
        args.out_usp_prot,
        args.out_usp_bed,
        args.out_usp_gff3,
    )

    args.fasta_file.close()
    args.fasta_file = open(args.fasta_file.name, "r")
    args.out_usp_prot.close()
    args.out_usp_prot = open(args.out_usp_prot.name, "r")

    pairs = tuple_fasta(fasta_file=args.out_usp_prot)
    have_lipo = []

    for each_pair in pairs:
        if len(each_pair[1]) <= args.max_size:
            try:
                have_lipo += find_lipobox(
                    pair=each_pair,
                    minimum=args.lipo_min_start,
                    maximum=args.lipo_max_start,
                    min_after=args.min_lipo_after,
                    max_after=args.max_lipo_after,
                )
            except (IndexError, TypeError):
                continue

    # print(len(have_lipo))
    # print(have_lipo)

    have_tmd_and_lipo = []
    # print(args.tmd_min_start)
    # print(args.tmd_max_start)
    # print(args.tmd_min_size)
    # print(args.tmd_max_size)

    for each_pair in have_lipo:
        try:
            have_tmd_and_lipo += find_tmd(
                pair=each_pair,
                minimum=args.tmd_min_start,
                maximum=args.tmd_max_start,
                TMDmin=args.tmd_min_size,
                TMDmax=args.tmd_max_size,
            )
        except (IndexError, TypeError):
            continue

    # print(len(have_tmd_and_lipo))
    # print(have_tmd_and_lipo)

    if args.switch == "all":
        pass
    else:
        range_of = args.switch
        range_of = re.search(("[\d]+:[\d]+"), range_of).group(0)
        start = int(range_of.split(":")[0])
        end = int(range_of.split(":")[1])
        have_lipo = parse_a_range(pair=have_tmd_and_lipo, start=start, end=end)

    total_have_tmd_and_lipo = len(have_tmd_and_lipo)

    ORF = []
    length = []
    candidate_dict = {k: v for k, v in have_tmd_and_lipo}
    with args.putative_usp_fa as f:
        for desc, s in candidate_dict.items():
            f.write(">" + str(desc))
            f.write("\n" + lineWrapper(str(s).replace("*", "")) + "\n")
            length.append(len(s))
            ORF.append(desc)
    #### Extra statistics
    args.out_usp_prot.close()
    all_orfs = open(args.out_usp_prot.name, "r")
    all_isps = open(args.putative_usp_fa.name, "r")
    # record = SeqIO.read(all_orfs, "fasta")
    # print(len(record))
    n = 0
    for line in all_orfs:
        if line.startswith(">"):
            n += 1
    all_orfs_counts = n

    c = 0
    for line in all_isps:
        if line.startswith(">"):
            c += 1
    all_isps_counts = c

    if ORF:
        bot_size = min(length)
        top_size = max(length)
        avg = (sum(length)) / total_have_tmd_and_lipo
        n = len(length)
        if n == 0:
            raise Exception("no median for empty data")
        if n % 2 == 1:
            med = length[n // 2]
        else:
            i = n // 2
            med = (length[i - 1] + length[i]) / 2
        with args.summary_usp_txt as f:
            f.write("total potential u-spanins: " + str(total_have_tmd_and_lipo) + "\n")
            f.write("average length (AA): " + str(avg) + "\n")
            f.write("median length (AA): " + str(med) + "\n")
            f.write("maximum orf in size (AA): " + str(top_size) + "\n")
            f.write("minimum orf in size (AA): " + str(bot_size) + "\n")
            f.write("ratio of isps found from naive orfs: " + str(c) + "/" + str(n))

        args.putative_usp_fa = open(args.putative_usp_fa.name, "r")
        gff_data = prep_a_gff3(
            fa=args.putative_usp_fa, spanin_type="usp", org=args.fasta_file
        )
        write_gff3(data=gff_data, output=args.putative_usp_gff)
    else:
        with args.summary_usp_txt as f:
            f.write("No Candidate USPs found")
            if have_lipo:
                f.write("\nLipoboxes were found here:\n")
                for each_lipo in have_lipo:
                    f.write(">" + str(each_lipo[0]))
                    f.write("\n" + lineWrapper(each_lipo[1].replace("*", "")) + "\n")
            else:
                f.write("\nNo Lipobox(es) were found within search restraints")
