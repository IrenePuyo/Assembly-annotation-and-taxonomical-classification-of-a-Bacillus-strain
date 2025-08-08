def read_fasta_multicontig(path):
    """Reads a multi-contig FASTA file.

    Returns:
        list of tuples: [(header, list_of_characters), ...]
    """
    contigs = []
    with open(path, "r") as f:
        header = None
        seq = []
        for line in f:
            line = line.strip()
            if line.startswith(">"):
                if header:
                    contigs.append((header, list(''.join(seq))))
                header = line
                seq = []
            else:
                seq.append(line)
        if header:
            contigs.append((header, list(''.join(seq))))
    return contigs


def read_corrections_tsv(path):
    """Reads corrections from a TSV file and prepares them for application.

    Returns:
        list: Sorted list of corrections as tuples (pos, original, corrected)
    """
    corrections = []
    with open(path, "r") as f:
        next(f)  # skip header
        for line in f:
            parts = line.strip().split('\t')
            while len(parts) < 3:
                parts.append('')
            pos_str, original, corrected = parts[:3]
            pos = int(pos_str)
            corrections.append((pos, original.upper(), corrected.upper()))
    return sorted(corrections, key=lambda x: -x[0])


def apply_corrections(sequence, corrections):
    """Applies corrections to a DNA sequence."""
    for pos, original, corrected in corrections:
        idx = pos - 1
        len_orig = len(original)
        current_segment = ''.join(sequence[idx:idx+len_orig])
        if original and current_segment != original:
            print(f"Warning: at position {pos}, expected '{original}' but found '{current_segment}'")
            return sequence
        sequence[idx:idx+len_orig] = list(corrected)
    return sequence


def write_fasta_multicontig(contigs, output_path):
    """Writes multiple contigs to a FASTA file with standard formatting."""
    with open(output_path, "w") as f:
        for header, sequence in contigs:
            f.write(header + "\n")
            for i in range(0, len(sequence), 60):
                f.write(''.join(sequence[i:i+60]) + "\n")


# --- Main Execution ---
if __name__ == "__main__":
    fasta_input = "assembly.fasta"
    tsv_input = "corrections.tsv"
    fasta_output = "corrected_genome.fasta"

    contigs = read_fasta_multicontig(fasta_input)
    corrections = read_corrections_tsv(tsv_input)

    corrected_contigs = []
    for i, (header, sequence) in enumerate(contigs):
        if i == 0:
            sequence = apply_corrections(sequence, corrections)
        corrected_contigs.append((header, sequence))

    write_fasta_multicontig(corrected_contigs, fasta_output)
    print("Corrections applied and file written successfully:", fasta_output)
