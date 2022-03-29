# bioscript
A repository for some useful bio-scripts.

**Summary Table**

Script | Type | System | Description | Note
--- | --- | --- | --- | ---
[L7_to_OTU](/L7_to_OTU) | `Bash` | `Linux` | Summarzied OTU table -> OTU table | *MacOS: gnu-opt required* 
[ko2keggL.sh](/ko2keggL.sh) | `Bash` | `Linux` | update koID -> KEGG levels | *MacOS: not tested*
[merge_bioms.R](/merge_bioms.R) | `R` | `Unix/Win` | merge biom files by #OTU ID | *MacOS: not tested*
[fq2fa.py](/fq2fa.py) | `Python` | `Unix/Win` | fastq -> fasta | *MacOS/Win: not tested*
[extract_RGI_fasta.py](/extract_RGI_fasta.py) | `Python/Bio,pandas` | `Unix/Win` | extract ORF using RGI output | *MacOS/Win: not tested*
[q2-core.sh](/q2-core.sh) | `QIIME 2` & [q2meta-grouped.py](/q2meta-grouped.py) | `Linux` | quick QIIME analysis with feature matrix | *MacOS: gnu-opt required*
[q2-coreN.sh](/q2-core.sh) | `QIIME 2` & [q2meta-grouped.py](/q2meta-grouped.py) | `Linux` | quick (non-phylogenetic) QIIME analysis with feature matrix | *MacOS: gnu-opt required*
[q2meta-grouped.py](q2meta-grouped.py) | `QIIME 2` | `Unix` | create grouped metadata for QIIME | *MacOS: not tested*
[fq2dir.sh](fq2dir.sh) | `Bash` | `Uniux` | fastqs to sample-specific directory | *Macos not tested*
[texlca.py](texlca.py) | `Python/pandas,argparse` | `Unix/Win` | simple LCA taxonomy on text (LCS) | *MacOS/Win: not tested*
