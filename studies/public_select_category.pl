#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include_clinical_research.lib";

my $query = new CGI;

# Set the variables for connecting to the database
[DELETED]

# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Set up category variables and get the categories
my @category_ids = ('0');
my %categories = ( 0 => '-- Select One --' );
my $sth = $dbh->prepare("SELECT id, name FROM category WHERE display = 'Yes' ORDER BY name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($id, $name);
while(($id, $name) = $sth->fetchrow) {
        push(@category_ids, $id); # Build the category ids array
        $categories{$id} = $name; # Build the categories hash
        }
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print $query->header;

# Start building the Web page
&Header;

print "<br><TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";
print $query->start_multipart_form(-action=>'public_show_category_study.pl', -name=>'selectCategory', -onChange=>'return jumpPage(this.form.selectCategory)');
print "<TR><td valign=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"10\" height=\"300\"></TD>\n";
print "<TD CLASS=\"text\" VALIGN=\"top\">\n";
print "Select a study category:&nbsp;";
print $query->scrolling_list(-name=>'category',
				-onchange=>'return jumpPage(this.form.category)',
                                -value=>[@category_ids], # List
                                -default=>['0'],
                                -size=>1,
                                -labels=>\%categories); # Hash
print "<p>&nbsp;</p><p>Not finding what you're looking for? Use the search box to the left to search the studies database.</p>";
print "</TD></TR>\n";
print $query->end_form;
print "</TABLE>\n";

# Add the bottom
&Footer;
