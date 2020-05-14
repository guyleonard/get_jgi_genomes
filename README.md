# Get JGI Genomes!
Download all the available Amino Acid sequences from the genomes contained within JGI's various -zomes and -cosms.

# Usage
Log in to JGI with your username and password (-u and -p) to generate the required 'cookie' file to allow your downloads to process. Then use one of the portal options (-f, -a or -P or -m with a version number) to download the amino acid sequences from all available genome projects. You can generate a list of all the available genomes with the '-l' option, no downloads will occur. XML files are automatically refreshed after 10 days, or if you delete the file and re-run your commands.

NB - Point releases with the '-zomes', e.g. 12.1 do not seem to work, so please only use whole integers. Metazome seems to be abandoned and sometimes has file download issues.

```
Usage:
  get_jgi_genomes [-u <username> -p <password>] | [-c <cookies>] [-f | -a | -P 12 | -m 3] (-l)

Required:
  -u <username>
  -p <password>
or
  -c <cookie file>
Options:
  -f Mycocosm aka fungi
  -a Phycocosm aka algae
  -P <version> PhytozomeV
  -m <metazome> MetazomeV
Listing:
  -l list only, no downloads
```

# Other Genome Download Tools
 * [Get Ensemble Genomes](https://github.com/guyleonard/get_ensembl_genomes)

# Broken?
If the downloads of the XML or AA files no longer work, it probably means JGI have changed something in the layout of their XML files, let me know and I will try and update it or pass along a pull request with your fixes.
