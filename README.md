# Get JGI Genomes!
Download all the available Amino Acid sequences from the genomes contained within JGI's various -zomes and -cosms.

# Usage
Login to JGI with your username and password (-u and -p) to generate the required 'cookie' file to allow your downloads to process. This will work for your current session only, and expires daily.

Then use one of the portal options (-f & -a or -P, & -m with a version number) to download the files from the available genome projects. You can also choose the type of data you wish to download (with -A, -C, -g or -t) and the default is to download amino acid (protein/peptide) sequences.

You can generate a list of all the available genomes with the '-l' option, this means no downloads will occur.

```
Usage:
  get_jgi_genomes [-u <username> -p <password>] | [-c <cookies>] [-f | -a | -P 12 | -m 3] (-i) (-l) (-A) (-C) (-g) (-t) (-q)

Required:
	-u <username>
	-p <password>
or
	-c <cookie file>
Portal Choice:
	-f Mycocosm aka fungi
	-a Phycocosm aka algae
	-P <version> PhytozomeV aka plants
	-m <version> MetazomeV aka metazoans
Portal File Options:
	-A get assembly
	-C get CDS
	-g get GFF
	-t get transcripts
JGI Taxa ID:
	-i <id> JGI ID of Genome Project
Other:
	-l list only, no downloads
```

NB - Point releases with the '-zomes', e.g. 12.1 do not seem to work, so please only use whole integers only.

XML files are automatically refreshed after 10 days, or if you delete the file and re-run your commands.

## Notes
### Phycocosm
As of writing (July 2020) the Phycocosm portal lists 77 genomes available, however not all of these are available in the XML. About 37 are available, the others - mostly archaeplastida - are available from Phytozome.

### Metazome
Metazome  does not seem to be maintained and occasionally has file download issues, generally it is very slow.

# Other Genome Download Tools
 * [Get Ensembl Genomes](https://github.com/guyleonard/get_ensembl_genomes)

# Broken?
If the downloads of the XML or AA files no longer work, it probably means JGI have changed something in the layout of their XML files, let me know and I will try and update it or pass along a pull request with your fixes.
