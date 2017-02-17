#!/usr/bin/env perl
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Basename;

use Getopt::Std;

use XML::LibXML;

# Instructions are from here: http://genome.jgi.doe.gov/help/download.jsf#api
# This is just a wrapper to make things easier...

my %options = ();
getopts( 'u:p:g:h', \%options ) or display_help();

if ( $options{h} ) { display_help(); }

if ( defined $options{u} && defined $options{p} ) {
    my $username = "$options{u}";
    my $password = "$options{p}";
    signin( $username, $password );

    if ( defined $options{g} ) {
        my $project = "$options{g}";
        print "Downloading XML\n";
        download_xml($project);

        my $all_or_filtered = "Filtered Models \(best\)";

        #my $all_or_filtered = "All models, Filtered and Not";

        print "Parsing XML\n";
        parse_xml( $project, $all_or_filtered );
    }
    else {
        print "No Project Option Given. Stopping. -g\n";
        exit(1);
    }
}
else {
    display_help();
}

sub display_help {
    print "Usage:\n";
    print "Required:\n";
    print "\t-u username\n";
    print "\t-p password\n";
    print "\t-g project (fungi, PhytozomeV11, MetazomeV3, ...)\n";
    print "Optional:\n";
    print "\t-x xml file\n";
    print "get_jgi_genomes.pl -u username -p password ----\n";
    exit(1);
}

# JGI Insist we log in, that's okay. You should be aware that different genome portals
# may have different licenses etc...up to the individual user to be aware of them.
# Let's login to the DOE JGI SSO
# We can do this with curl and our username/password
# This saves a cookie for use later, it will need refreshing.
sub signin {

    my $user = shift;
    my $pass = shift;

    if ( -A "cookies" > 1 || !-e "cookies" ) {
        print "Logging In...\n";
        my $login =
"curl 'https://signon.jgi.doe.gov/signon/create' --data-urlencode 'login=$user' --data-urlencode 'password=$pass' -c cookies > /dev/null";
        print "$login\n";
        system($login);
        print "Successfully Logged In!\n";
    }
    else {
        print "Skipping, should already be logged in\n";
    }
}

# Now let's use curl again with our cookie signon and scrape the XML
# Only refresh if the file is older than 10 days...You can change this as you like
sub download_xml {
    my $portal = shift;

    if ( !-e "$portal\_files.xml" ) {    #> 10 ) {

        # Get portal List
        print "Downloading $portal XML - This may take some time...\n";
        my $get_xml =
"curl http://genome.jgi.doe.gov/ext-api/downloads/get-directory?organism=$portal -b cookies > $portal\_files.xml";
        system($get_xml);
    }
    else {
        print "$portal\_files.xml has not been modified in > 10 days, skipping download.\n";
    }
}

# I can't get the XML parsing to work when "&quot;" exists in the file
# let's cheat and remove it with sed?

## Parse the XML DOM
sub parse_xml {

    my $portal = shift;

    my $xml_file = "$portal\_files.xml";

    my $dom = XML::LibXML->load_xml( location => $xml_file, no_blanks => 1 );

    my $all_or_filtered = "Filtered Models \(best\)";

    #my $all_or_filtered = "All models, Filtered and Not";

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
        my @cast = map { $_->to_literal(); } $file->findnodes('./file/@url');

        #print "\n". $cast . "\n";

        foreach my $taxa (@cast) {
            my ( $file, $dir, $ext ) = fileparse( $taxa, '\.gz' );
            my $download = "curl --silent 'http://genome.jgi.doe.gov/$taxa' -b cookies > $file.$ext";

            print "$download\n";
            system($download);
        }
    }
}
