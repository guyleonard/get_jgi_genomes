# Get JGI Genomes!
Download files from the genomes contained within JGI's various -zomes and -cosms.

# Usage
Login to JGI with your username and password (-u and -p) to generate the required 'cookie' file to allow your downloads to process. This will work for your current session only, and expires daily.

Then use one of the portal options (-f, -a, or -P, -m with a version number) to download the files from the available genome projects. You can also choose the type of data you wish to download (with -A, -C, -g or -t), the default is to download amino acid (protein/peptide) sequences.

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
# Notes
## Phycocosm
As of writing (July 2020) the Phycocosm portal lists 77 genomes available, however not all of these seem to be available in the XML for that portal. Only about 37 of them are available, the others - mostly from archaeplastida - are available from Phytozome.

## Phytozome
Currently versions 9 to 12 work with this script (point releases, e.g. 12.1, do not seem to work, so please use whole integers only). The newer, 'phytozome-next' or V13 is available at "https://phytozome-next.jgi.doe.gov/". Currently, I see no way of adding access this to the script. There is some form of limited CLI download, but it looks like you need to have an active connection in your browser to generate the download link, and you also have to select files via the clunky search interface (e.g. how do you select all predicted proteins only, it looks like you have to manually select them for each taxa).

## Metazome
Metazome does not seem to be maintained, and occasionally has file download issues, generally it is very slow, but version '3' seems to download. It also looks like it is being ported to the new-style of interface that is available with phytozome-next.

## Other
XML files are automatically refreshed after 10 days, or if you delete the file and re-run your commands.

Output is in your local folder within a directory named after the portal and the type of data you requested.

# Examples
To login:
```bash
./bin/get_jgi_genomes -u your.email@address.com -p y0uR_P@$$W0r4
```

To download a list of all protein files from Mycocosm after you have logged in:
```bash
./bin/get_jgi_genomes -c signon.cookie -f -l
```

To download all CDS files from Phycocosm after you have logged in:
```bash
./bin/get_jgi_genomes -c signon.cookie -a -C
```

To download all assembly files from Phytozome V12 after you have logged in:
```bash
./bin/get_jgi_genomes -c signon.cookie -P 12 -A
```

To download proteins of 'Boleraceacapitata' from Phytozome V12 after you have logged in:
```bash
./bin/get_jgi_genomes -c signon.cookie -P 12 -i Boleraceacapitata
```

To download transcripts of 'Trire2' from Mycocosm after you have logged in:
```bash
./bin/get_jgi_genomes -c signon.cookie -f -i Trire2 -t
```

# Other Genome Download Tools
 * [Get Ensembl Genomes](https://github.com/guyleonard/get_ensembl_genomes)

# Broken?
If the downloads of the XML or AA files no longer work, it probably means JGI have changed something in the layout of their XML files, let me know and I will try and update it or feel free to pass along a pull request with your fixes.
