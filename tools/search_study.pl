#! /usr/bin/perl -wT 

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the search term into a variable
my $searchterm = $query->param('search_term');
$searchterm =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters

# Set the variables for connecting to the database
[DELETED]

# Start building the Web page
print $query->header;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<CENTER>\n<H3 CLASS=\"large_title\">Editing Tools Search Results</H3><H4 CLASS=\"title\">Click the link to view the study.</H4>\n";

print "<TABLE WIDTH=\"700\" BORDER=\"1\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Note: Wildcards used only after pi_last_name, sc_last_name to make use of
# the "name_index" index in the "study" database table
my $sth = $dbh->prepare("SELECT id, pi_last_name, sc_last_name, SUBSTRING(study_name, 1, 50) AS study, SUBSTRING(description, 1, 105) AS descrip FROM study WHERE ((((((pi_last_name LIKE '$searchterm%') || (sc_last_name LIKE '$searchterm%')) || (study_name LIKE '%$searchterm%')) || (description LIKE '%$searchterm%'))  || (participate_who LIKE '%$searchterm%'))  || (participate_what LIKE '%$searchterm%')) ORDER BY study") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");

my $rows = $sth->rows;

if ($rows == 0) {
	print "<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">No results found with search term \"$searchterm\".</TD>\n</TR>\n";
	} elsif ($rows != 0 ) {
		if ($rows == 1) {
		print "<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">The search found 1 study with search term \"$searchterm\".</TD>\n</TR>\n";
		} else {
		print "<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">The search found $rows studies with search term \"$searchterm\".</TD>\n</TR>\n";
		}
		while(my $results = $sth->fetchrow_arrayref) {
			my $description = @$results[4] . "...";
			print "<TR>\n<TD CLASS=\"copy\">Study Name: <A HREF=\"show_study.pl?id=@$results[0]\">@$results[3]</A> PI: @$results[1] SC: @$results[2]<BR>Description: $description</TD>\n</TR>";
		}
}

$sth->finish || die("Could not finish study select: $DBI::errstr");

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print "</TABLE>\n";
print "</CENTER>\n";
print $query->end_html;
