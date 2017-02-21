#!/usr/bin/env perl
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Basename;
use File::Path qw(make_path);

use Getopt::Std;

use XML::LibXML;

# Instructions are from here: http://genome.jgi.doe.gov/help/download.jsf#api
# This is just a wrapper to make things easier...

my $cookies = 'cookies';
my ($username, $password, $outdir, $project);

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
if ( defined $options{o} && defined $options{g}) {
    $outdir = "$options{o}";
    $project = "$options{g}";

    print "Downloading XML from JGI Project: $project\n";
    download_xml($project);
}

# Parsing
my $all_or_filtered = "Filtered Models \(best\)";

#my $all_or_filtered = "All models, Filtered and Not";

print "Parsing XML\n";
my $list = "false";
if ($options{l}) {
    $list = "true";
    print "\tOutput: List Only\n";
    parse_xml( $project, $all_or_filtered, $outdir, $list );
}
else {
    parse_xml( $project, $all_or_filtered, $outdir, $list );
}

#}
#else {
#    print "No Project Option Given. Stopping. -g\n";
#    exit(1);
#}

#else {
#    display_help();
#}

sub display_help {
    print "Usage:\n";
    print "Required:\n";
    print "\t-u username\n";
    print "\t-p password\n";
    print "or\n";
    print "-c cookie file\n";
    print "\t-g project (fungi)\n";
    print "Optional:\n";
    print "\t -l list only";
    #print "\t-x xml file\n";
    print "---\n";
    print "get_jgi_genomes.pl [-u <username> -p <password>] | [-c <cookies>] -g <portal> -o <outdir> -l\n";
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
"curl http://genome.jgi.doe.gov/ext-api/downloads/get-directory?organism=$portal -b $cookies > $portal\_files.xml"
        );
    }
    else {
        print "\t$portal\_files.xml has not been modified in > 10 days, skipping download.\n";
    }

    # I can't get the XML parsing to work when "&quot;" exists in the file
    # let's cheat and remove it with sed?
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

    foreach my $file (
        $dom->findnodes(
                '/organismDownloads/folder[@name="Files"]/folder/folder[@name="'
              . $all_or_filtered
              . '"]/folder[@name="Proteins"]'
        )
      )
    {
        #print "\n" . $file->findnodes('./file/@label') . "\n";
        #my $cast = join "\n", map { $_->to_literal(); } $file->findnodes('./file/@url');
        #print "\n". $cast . "\n";
        if ( $list eq "true" ) {
            my @list = map { $_->to_literal(); } $file->findnodes('./file/@label');
            genome_list( \@list, $outdir, $portal );
        }
        else {
            my @urls = map { $_->to_literal(); } $file->findnodes('./file/@url');
            download_files( \@urls, $outdir );
        }
    }
}

sub genome_list {
    my @list   = @{ $_[0] };
    my $outdir = $_[1];
    my $portal = $_[2];

    my %unique_list = map { $_, 1 } @list;
    my @unique = sort keys %unique_list;

    my $filename = "$outdir\/$portal\_list.txt";
    open my $fileout, '>', $filename;

    foreach my $taxon (@unique) {
        print $fileout "$taxon\n";
    }

    close($fileout);
}

sub download_files {
    my @urls   = @{ $_[0] };
    my $outdir = $_[1];

    foreach my $taxa (@urls) {
        my ( $file, $dir, $ext ) = fileparse( $taxa, '\.gz' );
        if ( -e "$outdir\/$file$ext" ) {
            print "\t\tSkipping: $file Exists\n";
        }
        else {
            print "\tRetrieving: $file\n";
            run_cmd("curl --silent 'http://genome.jgi.doe.gov/$taxa' -b cookies > $outdir\/$file$ext");
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
