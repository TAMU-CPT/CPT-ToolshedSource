import argparse
import re
import sys


class BlastProteinResultParser:
    def __init__(self, blast_file):
        self.blast_file = blast_file
        self.results = {}

    def parse_blast(self):
        for line in self.blast_file:
            parts = line.strip().split("\t")
            query_id = parts[0]
            subject_titles = parts[2].split("<>")
            for title in subject_titles:
                organism = self.extract_organism(title)
                if organism:
                    if organism not in self.results:
                        self.results[organism] = {
                            "unique_queries": set(),
                            "unique_hits": set(),
                        }
                    #  "unique query" == query proteins had a LEAST one match in organism
                    self.results[organism]["unique_queries"].add(query_id)
                    #  "unique hits" == unique proteins from eahc organism were matched by ANY of the queries
                    self.results[organism]["unique_hits"].add(parts[1])

    @staticmethod
    def extract_organism(title):
        match = re.search(r"\[(.*?)\]", title)
        return match.group(1) if match else None

    def get_top_hits(self, num_hits, key="unique_queries"):
        def sort_key(item):
            return len(item[1][key])

        sorted_results = sorted(self.results.items(), key=sort_key, reverse=True)
        return sorted_results[:num_hits]

    def print_results(
        self, num_hits, sort_key="unique_queries", output_file=sys.stdout
    ):
        top_hits = self.get_top_hits(num_hits, sort_key)
        print(f"# Top {num_hits} Hits", file=output_file)
        print(
            "Rank\tPhage Name\tUnique Query Matches\tUnique Subject Hits",
            file=output_file,
        )
        for rank, (organism, data) in enumerate(top_hits):
            print(
                f"{rank}\t{organism}\t{len(data['unique_queries'])}\t{len(data['unique_hits'])}",
                file=output_file,
            )


def main():
    parser = argparse.ArgumentParser(
        description="Parse BLAST results and group by 'top hits' to an organism"
    )
    parser.add_argument("blast", type=argparse.FileType("r"), help="Blast Results")
    parser.add_argument(
        "--hits", type=int, default=5, help="Number of top hits to display"
    )
    parser.add_argument(
        "--output",
        type=argparse.FileType("w"),
        default="-",
        help="Output file (default: stdout)",
    )
    parser.add_argument(
        "--sort",
        choices=["unique_queries", "unique_hits"],
        default="unique_queries",
        help="Sort results by 'unique_queries' (default) or 'unique_hits'",
    )
    args = parser.parse_args()

    blast_parser = BlastProteinResultParser(args.blast)
    blast_parser.parse_blast()
    blast_parser.print_results(args.hits, args.sort, args.output)

    args.output.close()


if __name__ == "__main__":
    main()
