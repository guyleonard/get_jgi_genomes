# get_jgi_genomes
JGI offers several ways to download its genomic data:

 1) Individual Download - You can go to the specific genome portal and download whatever file you need from that project e.g [here](http://genome.jgi.doe.gov/pages/dynamicOrganismDownload.jsf?organism=Aaoar1).
 
 2) Multiple Download - Following the same logic as above, instead of just a single project ID, e.g. "Aaoar1" you can use a global project such as "fungi", like so [here](http://genome.jgi.doe.gov/pages/dynamicOrganismDownload.jsf?organism=fungi).
 
 3) GLOBUS - I am not going to even bother explaining this one as it would fill up most of this repo with bad vibes. GLOBUS not even once.

All three are web based methods and are slow and prone to connection time outs and take time to scan for files and load the right interface etc etc. Luckily JGI also keep an XML document (by way of a rudimentary API) of all their projects with links to the download location of each file! This is good for us, XML is easily parseable!

**NB - Users should be aware that individual genome projects may have their own usage/licensing conditions - it is up to each user to make themselves aware of this before using the data.**

Initially I will only focus on the Fungi portal (Mycocosm - although not, see Notes) and add in various other portals as needed, or on request.

## Usage

## Notes

### XML Layout

Here is a rough layout of the XML document. I have shown the path to get to the predicted proteins for each project within the 'fungi' project. You should now read the section JGI Quirks...

    - organismDownloads->name=fungi
      |
      + folder->name=Raw Data
      |
      + folder->name=Mycocosm
      |
      + folder->name=Files
        |
        + folders->names=(ESTs and EST Clusters, Additonal Files, Assembly)->folders...
        |
        + folder->name=Annotation
          |
          + folder->name=All models, Filtered and Not
          |
          + folder->name=Filtered Models ("best")
            |
            + folders
            |
            + folder->name=Proteins
              |
              + files->label,url,filename,size,timestamp,project,md5
              
### JGI Quirks

 * Although the portal is called "Mycocosm", this list only seems to contain the list of newly added fungi from [here](http://jgi.doe.gov/our-science/science-programs/fungal-genomics/recent-fungal-genome-releases/) and not the total content of the "fungi" portal which is contained in "Files". :|
 
 * The two lists: 'Filtered...' and 'All...' are not what you might initially think. :|
  * All models, Filtered and Not = 570, 566 unique
  * Filtered Models (best) = 1612, 757 unique

