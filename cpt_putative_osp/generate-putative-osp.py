#!/usr/bin/env python
import argparse
from cpt import OrfFinder
from spaninFuncs import *
import re

### Requirement Inputs
#### INPUT : Genomic FASTA
#### OUTPUT : Putative OSP candidates in FASTA format.
######### Optional OUTPUT: "Complete" potential ORFs, in BED/FASTAs/GFF3 formats
### Notes:
####### As of 2.13.2020 - RegEx pattern: [ACGSILMFTV][^REKD][GASNL]C for LipoRy
if __name__ == "__main__":

    # Common parameters for both ISP / OSP portion of scripts

    parser = argparse.ArgumentParser(
        description="Get putative protein candidates for spanins"
    )

    parser.add_argument(
        "fasta_file", type=argparse.FileType("r"), help="Fasta file"
    )  # the "input" argument

    parser.add_argument(
        "-f",
        "--format",
        dest="seq_format",
        default="fasta",
        help="Sequence format (e.g. fasta, fastq, sff)",
    )  # optional formats for input, currently just going to do ntFASTA

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
        help="switch between ALL putative osps, or a range. If not all, insert a range of two integers separated by a colon (:). Eg: 1234:4321",
    )

    # osp parameters
    parser.add_argument(
        "--osp_min_len",
        dest="osp_min_len",
        default=30,
        help="Minimum ORF length, measured in codons",
        type=int,
    )
    parser.add_argument(
        "--max_osp",
        dest="max_osp",
        default=200,
        help="Maximum ORF length, measured in codons",
        type=int,
    )
    parser.add_argument(
        "--osp_on",
        dest="out_osp_nuc",
        type=argparse.FileType("w"),
        default="_out_osp.fna",
        help="Output nucleotide sequences, FASTA",
    )
    parser.add_argument(
        "--osp_op",
        dest="out_osp_prot",
        type=argparse.FileType("w"),
        default="_out_osp.fa",
        help="Output protein sequences, FASTA",
    )
    parser.add_argument(
        "--osp_ob",
        dest="out_osp_bed",
        type=argparse.FileType("w"),
        default="_out_osp.bed",
        help="Output BED file",
    )
    parser.add_argument(
        "--osp_og",
        dest="out_osp_gff3",
        type=argparse.FileType("w"),
        default="_out_osp.gff3",
        help="Output GFF3 file",
    )
    parser.add_argument(
        "--osp_min_dist",
        dest="osp_min_dist",
        default=10,
        help="Minimal distance to first AA of lipobox, measured in AA",
        type=int,
    )
    parser.add_argument(
        "--osp_max_dist",
        dest="osp_max_dist",
        default=50,
        help="Maximum distance to first AA of lipobox, measured in AA",
        type=int,
    )
    parser.add_argument(
        "--min_lipo_after",
        dest="min_lipo_after",
        default=25,
        help="minimal amount of residues after lipobox",
        type=int,
    )
    parser.add_argument(
        "--max_lipo_after",
        dest="max_lipo_after",
        default=170,
        help="minimal amount of residues after lipobox",
        type=int,
    )
    parser.add_argument(
        "--putative_osp",
        dest="putative_osp_fa",
        type=argparse.FileType("w"),
        default="_putative_osp.fa",
        help="Output of putative FASTA file",
    )
    parser.add_argument(
        "--summary_osp_txt",
        dest="summary_osp_txt",
        type=argparse.FileType("w"),
        default="_summary_osp.txt",
        help="Summary statistics on putative o-spanins",
    )
    parser.add_argument(
        "--putative_osp_gff",
        dest="putative_osp_gff",
        type=argparse.FileType("w"),
        default="_putative_osp.gff3",
        help="gff3 output for putative o-spanins",
    )
    parser.add_argument("--osp_mode", action="store_true", default=True)

    # parser.add_argument('-v', action='version', version='0.3.0') # Is this manually updated?
    args = parser.parse_args()

    the_args = vars(parser.parse_args())

    ### osp output, naive ORF finding:
    osps = OrfFinder(args.table, args.ftype, args.ends, args.osp_min_len, args.strand)
    osps.locate(
        args.fasta_file,
        args.out_osp_nuc,
        args.out_osp_prot,
        args.out_osp_bed,
        args.out_osp_gff3,
    )

    """
    ### For Control: Use T7 and lambda; 
    # Note the distance from start codon to lipobox region for t7
    o-spanin
    18,7-------------------------------------------------LIPO----------------------------------
    >T7_EOS MSTLRELRLRRALKEQSVRYLLSIKKTLPRWKGALIGLFLICVATISGCASESKLPESPMVSVDSSLMVEPNLTTEMLNVFSQ
    -----------------------------LIPO----------------------------------------
    > lambda_EOS MLKLKMMLCVMMLPLVVVGCTSKQSVSQCVKPPPPPAWIMQPPPDWQTPLNGIISPSERG
    """
    args.fasta_file.close()
    args.fasta_file = open(args.fasta_file.name, "r")
    args.out_osp_prot.close()
    args.out_osp_prot = open(args.out_osp_prot.name, "r")

    pairs = tuple_fasta(fasta_file=args.out_osp_prot)
    have_lipo = []  # empty candidates list to be passed through the user input

    for each_pair in pairs:
        if len(each_pair[1]) <= args.max_osp:
            try:
                have_lipo += find_lipobox(
                    pair=each_pair,
                    minimum=args.osp_min_dist,
                    maximum=args.osp_max_dist,
                    min_after=args.min_lipo_after,
                    max_after=args.max_lipo_after,
                    osp_mode=args.osp_mode,
                )
            except (IndexError, TypeError):
                continue

    if args.switch == "all":
        pass
    else:
        # for each_pair in have_lipo:
        range_of = args.switch
        range_of = re.search(("[\d]+:[\d]+"), range_of).group(0)
        start = int(range_of.split(":")[0])
        end = int(range_of.split(":")[1])
        have_lipo = parse_a_range(pair=have_lipo, start=start, end=end)
        # print(have_lipo)
        # matches

    # have_lipo = []
    # have_lipo = matches
    total_osp = len(have_lipo)
    # print(have_lipo)
    # print(total_osp)

    # print(type(have_lipo))

    # for i in have_lipo:
    #    print(i)

    # export results in fasta format
    ORF = []
    length = []  # grabbing length of the sequences
    candidate_dict = {k: v for k, v in have_lipo}
    with args.putative_osp_fa as f:
        for desc, s in candidate_dict.items():  # description / sequence
            f.write(">" + str(desc))
            f.write("\n" + lineWrapper(str(s).replace("*", "")) + "\n")
            length.append(len(s))
            ORF.append(desc)
    if not length:
        raise Exception("Parameters yielded no candidates.")
    bot_size = min(length)
    top_size = max(length)
    avg = (sum(length)) / total_osp
    n = len(length)
    if n == 0:
        raise Exception("no median for empty data")
    if n % 2 == 1:
        med = length[n // 2]
    else:
        i = n // 2
        med = (length[i - 1] + length[i]) / 2

    args.out_osp_prot.close()
    all_orfs = open(args.out_osp_prot.name, "r")
    all_osps = open(args.putative_osp_fa.name, "r")
    # record = SeqIO.read(all_orfs, "fasta")
    # print(len(record))
    #### Extra stats
    n = 0
    for line in all_orfs:
        if line.startswith(">"):
            n += 1
    all_orfs_counts = n

    c = 0
    for line in all_osps:
        if line.startswith(">"):
            c += 1
    all_osps_counts = c

    with args.summary_osp_txt as f:
        f.write("total potential o-spanins: " + str(total_osp) + "\n")
        f.write("average length (AA): " + str(avg) + "\n")
        f.write("median length (AA): " + str(med) + "\n")
        f.write("maximum orf in size (AA): " + str(top_size) + "\n")
        f.write("minimum orf in size (AA): " + str(bot_size) + "\n")
        # f.write(f"ratio of osps found from naive orfs: {c}/{n}")
        f.write("ratio of osps found from naive orfs: " + str(c) + "/" + str(n))
    # Output the putative list in gff3 format:
    args.putative_osp_fa = open(args.putative_osp_fa.name, "r")
    gff_data = prep_a_gff3(
        fa=args.putative_osp_fa, spanin_type="osp", org=args.fasta_file
    )
    write_gff3(data=gff_data, output=args.putative_osp_gff)
