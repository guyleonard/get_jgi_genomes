#!/usr/bin/env perl
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Basename;
use File::Find::Rule;
use File::Path qw(make_path);

use Getopt::Std;

use List::MoreUtils qw(uniq);

use XML::LibXML;

# Instructions are from here: http://genome.jgi.doe.gov/help/download.jsf#api
# This is just a wrapper to make things easier...

my $cookies = 'cookies';
my ( $username, $password, $outdir, $project );

my %options = ();
getopts( 'u:p:c:g:o:lh', \%options ) or display_help();

# Help
if ( $options{h} ) { display_help(); }

# Signin Options / Cookies
if ( defined $options{u} && defined $options{p} ) {
    $username = "$options{u}";
    $password = "$options{p}";
    signin( $username, $password );
}
elsif ( defined $options{c} ) {
    $cookies = $options{c};
    print "User supplied cookie, skipping signin process.\n";
}
else {
    display_help();
}

# Download Project XML & Output Dir
if ( defined $options{o} && defined $options{g} ) {
    $outdir  = "$options{o}";
    $project = "$options{g}";

    print "Downloading XML from JGI Project: $project\n";
    download_xml($project);
}
else {
    print "No Output Directory or Group Project ID\n";
    exit(1);
}

# Parsing
my $all_or_filtered = "Filtered Models \(best\)";

#my $all_or_filtered = "All models, Filtered and Not";

print "Parsing XML\n";
my $list = "false";
if ( $options{l} ) {
    $list = "true";
    print "\tOutput: List Only\n";
    parse_xml( $project, $all_or_filtered, $outdir, $list );
}
else {
    parse_xml( $project, $all_or_filtered, $outdir, $list );
}

sub display_help {
    print "Usage:\n";
    print "  get_jgi_genomes.pl [-u <username> -p <password>] | [-c <cookies>] -g <portal> -o <outdir> (-l)\n\n";
    print "Required:\n";
    print "  -u <username>\n";
    print "  -p <password>\n";
    print "or\n";
    print "  -c <cookie file>\n";
    print "and\n";
    print "  -g <project> (e.g. fungi)\n";
    print "---\n";
    print "Optional:\n";
    print "  -l list individual projects only to file (no downloads)\n";

    #print "\t-x xml file\n";
    exit(1);
}

# JGI insist we log in, that's okay. You should be aware that different genome portals
# may have different licenses etc...it's up to the individual user to be aware of these.
# So, let's login to the DOE JGI SSO
# We can do this with curl and our username/password
# This saves a cookie file for use later, it will need refreshing.
sub signin {

    my $user = shift;
    my $pass = shift;

    if ( -A "cookies" > 1 || !-e "cookies" ) {
        print "Logging In...\n";
        run_cmd(
"curl --silent 'https://signon.jgi.doe.gov/signon/create' --data-urlencode 'login=$user' --data-urlencode 'password=$pass' -c cookies > /dev/null"
        );
        print "Successfully Logged In!\n";
    }
    else {
        print "Already logged in...\n";
    }
}

# Now let's use curl again with our cookie signon and scrape the XML
# Only refresh if the file is older than 10 days...You can change this as you like
sub download_xml {
    my $portal = shift;

    if ( !-e "$portal\_files.xml" ) {    #> 10 ) {

        # Get portal List
        print "Downloading $portal XML - This may take some time...\n";
        run_cmd(
"curl https://genome.jgi.doe.gov/ext-api/downloads/get-directory?organism=$portal -b $cookies > $portal\_files.xml"
        );
    }
    else {
        print "\t$portal\_files.xml has not been modified in > 10 days, skipping download.\n";
    }

    # I can't get the XML parsing to work when "&quot;" exists in the file
    # let's cheat and remove it with sed?
    run_cmd("sed -i \'s/&quot;//g\' $portal\_files.xml")
}

## Parse the XML DOM
sub parse_xml {

    my $portal = shift;

    my $xml_file = "$portal\_files.xml";

    my $dom = XML::LibXML->load_xml( location => $xml_file, no_blanks => 1 );

    my $all_or_filtered = shift;    #"Filtered Models \(best\)";

    #my $all_or_filtered = "All models, Filtered and Not";

    my $outdir = shift;

    my $list = shift;

    if ( !-d $outdir ) {
        make_path($outdir);
    }

    # the XML path changed somewhere between November 2017 and March 2018
    foreach my $file (
        $dom->findnodes(
                '/organismDownloads[@name="fungi"]/folder[@name="Files"]/folder[@name="Annotation"]/folder[@name="'
              . $all_or_filtered
              . '"]/folder[@name="Proteins"]/folder[@name="global"]/folder[@name="dna"]/folder[@name="projectdirs"]/folder[@name="fungal"]/folder[@name="mycocosm"]/folder[@name="portal"]/folder[@name="downloads"]/folder'
        )
      )
    {
        if ( $list eq "true" ) {

            # Here we get both the "label" which is the taxon name (e.g. Genus species strain version)
            # and also the URLs - this is because I want to output the ID that JGI uses for projects
            # and these are not one of the variables, but do exist in the filepath
            my @list = map { $_->to_literal(); } $file->findnodes('./file/@label');
            my @urls = map { $_->to_literal(); } $file->findnodes('./file/@url');
            genome_list( \@list, \@urls, $outdir, $portal );
        }
        else {
            my @urls = map { $_->to_literal(); } $file->findnodes('./file/@url');
            download_files( \@urls, $outdir );
        }
    }
}

sub genome_list {
    my @list = @{ $_[0] };
    my @urls = @{ $_[1] };

    # make list uniq but preserve order
    my @uniq_list = uniq(@list);

    # filter out all gff3 and other entries
    @urls = grep ! /gff3|ipr|go\.tab|kegg|kog|signalp|alleles|unsupported|primary|secondary|domain|old\_|diploid/i, @urls;
    # some species have two, y'know just for fun...
    # Capcor1,Capep1,Claps1,Claye1,Kurca1,Metro1,Pendig1,Pengri1,Penita1,Sodal1,Symat1,Trias8904
    @urls = grep ! /Capcor1\_GeneCatalog\_proteins\_20160826\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Capep1\_GeneCatalog\_proteins\_20160826\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Claps1\_GeneCatalog\_proteins\_20160826\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Claye1\_GeneCatalog\_proteins\_20160828\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Kurca1\_GeneCatalog\_proteins\_20160603\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Metro1\_GeneCatalog\_proteins\_20160603\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Pendig1\_GeneCatalog\_proteins\_20170530\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Pengri1\_GeneCatalog\_proteins\_20170529\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Penita1\_GeneCatalog\_proteins\_20170529\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Sodal1\_GeneCatalog\_proteins\_20130716\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Symat1\_GeneCatalog\_proteins\_20150304\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Trias8904\_GeneCatalog\_proteins\_20170712\.aa\.fasta\.gz/i, @urls;
    @urls = grep ! /CocheC5\_1\_GeneModels\_FilteredModels1\_aa\.fasta\.gz/i, @urls;
    @urls = grep ! /Copci\_AmutBmut1\_GeneModels\_FrozenGeneCatalog\_20160912\_aa\.fasta\.gz/, @urls;
    @urls = grep ! /Mgraminicolav2\.FilteredModels1\.proteins\.fasta\.gz/, @urls;
    @urls = grep ! /Pstipitisv2\.FilteredModels1\.proteins\.gz/, @urls;
    @urls = grep ! /Pospl1\_FilteredModels2\_proteins\.fasta\.gz/, @urls;
    @urls = grep ! /TreeseiV2\_FilteredModelsv2\.0\.proteins\.fasta\.gz/, @urls;
    # remove Aciri1_meta for now
    #@urls = grep ! /Aciri1\_meta/i, @urls;

    my $outdir = $_[2];
    my $portal = $_[3];

    # create a hash of the same length arrays
    # it doesn't matter that the hash will
    # remove "duplicates" - where there are more
    # than one file for each taxa - we only care
    # about the taxon name...
    my %hash;
    @hash{@uniq_list} = @urls;

    my $filename = "$outdir\/$portal\_list.txt";
    open my $fileout, '>>', $filename;

    foreach ( sort keys %hash ) {
        my $taxa = $_;
        my $url  = $hash{$_};

        my @jgi_id = split /\//, $url;
        #print @jgi_id;
        # URL from XML
        # global/dna/projectdirs/fungal/mycocosm/portal/downloads/Aaoar1/Aaoar1_GeneCatalog_proteins_20140429.aa.fasta.gz
        # Actual JGI download URL
        # https://genome.jgi.doe.gov/portal/Aaoar1/download/Aaoar1_GeneCatalog_proteins_20140429.aa.fasta.gz
        print $fileout "$taxa\t$jgi_id[8]\thttps://genome.jgi.doe.gov/portal/$jgi_id[8]/download/$jgi_id[9]\n";
    }

    close($fileout);
}

# I can't seem to get curl to work sometimes
# but
# wget --load-cookies=cookies https://file.gz
# works
# also changed from http to https 

sub download_files {
    my @urls   = @{ $_[0] };
    my $outdir = $_[1];

    foreach my $current (@urls) {
        my ( $file, $dir, $ext ) = fileparse( $current, '\.gz' );
        my @jgi_id = split /\//, $dir;
        my $taxa = "$jgi_id[8]";

        my @file_match = File::Find::Rule->file()->name("$file$ext")->in("$outdir");

        if ( grep( /$file$ext/, @file_match ) ) {
            print "\t\tSkipping: $file$ext Exists\n";
        }
        else {
            print "\tRetrieving: $file\n";
            if ( $file =~ /gff/igs ) {
                run_cmd("curl --silent 'https://genome.jgi.doe.gov/portal/$taxa/download/$file$ext' -b cookies > $outdir\/gff\/$file$ext");
            }
            elsif ( $file =~ /alleles/igs ) {
                run_cmd("curl --silent 'https://genome.jgi.doe.gov/portal/$taxa/download/$file$ext' -b cookies > $outdir\/alleles\/$file$ext");
            }
            elsif ( $file =~ /tab/igs ) {
                run_cmd("curl --silent 'https://genome.jgi.doe.gov/portal/$taxa/download/$file$ext' -b cookies > $outdir\/tab\/$file$ext");
            }
            else {
                run_cmd("curl --silent 'https://genome.jgi.doe.gov/portal/$taxa/download/$file$ext' -b cookies > $outdir\/fasta\/$file$ext");
            }
        }
    }
}

sub run_cmd {
    my ( $cmd, $quiet ) = @_;
    msg("Running: $cmd") unless $quiet;
    system($cmd) == 0 or error("Error $? running command");
}

sub error {
    msg(@_);
    exit(1);
}

sub msg {
    print STDERR "@_\n";
}
