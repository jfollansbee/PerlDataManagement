#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include.lib";

my $query = new CGI;

# Get the search term into a variable
my $searchterm = $query->param('search_term');
$searchterm =~ s/(\;|\>|\<|\||\\n\f\r)//gi;	# Remove dangerous characters
my $p = $query->param('p');
$p =~ s/(\;|\>|\<|\||\\n\f\r)//gi;	# Remove dangerous characters

# Set the variables for connecting to the database
[DELETED]

print $query->header;

# Start building the Web page
&Header;

print "<TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"4\" CELLSPACING=\"4\">\n";

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the number of available studies
my $sth = $dbh->prepare("SELECT COUNT(id) AS count FROM study WHERE display = 'Yes'") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");
my $study_count = $sth->fetchrow;
$sth->finish || die("Could not finish study select: $DBI::errstr");

# Note: Wildcards used only after pi_last_name, sc_last_name to make use of
# the "name_index" index in the "study" database table
# Set the high and low values for the "Go to page" numbers
my $high = ($p * 5);
my $low = (($p * 5) - 5);
my $counter = 1;	# The counter is how we know what rows to display
my $onpage;

$sth = $dbh->prepare("SELECT id, SUBSTRING(study_name, 1, 50) AS study, SUBSTRING(description, 1, 105) AS descrip FROM study WHERE (display = 'Yes') && ((((((pi_last_name LIKE '$searchterm%') || (sc_last_name LIKE '$searchterm%')) || (study_name LIKE '%$searchterm%')) || (description LIKE '%$searchterm%'))  || (participate_who LIKE '%$searchterm%'))  || (participate_what LIKE '%$searchterm%')) ORDER BY study") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");

my $rows = $sth->rows;

if ($rows == 0) {
	print "<TR>\n<TD VALIGN=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"6\ height=\"1\"></TD><TD CLASS=\"text\">No results found with search term \"$searchterm.\"  $study_count studies searched.</TD>\n</TR>\n";
	} elsif ($rows != 0 ) {
		if ($rows == 1) {
		print "<TR>\n<TD VALIGN=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"6\ height=\"1\"></TD><TD CLASS=\"text\">The search found 1 study with search term \"$searchterm.\" $study_count studies searched.</TD>\n</TR>\n";
		} else {
		if ($rows > 5) { $onpage = "You are on page " . $p . "." } else { $onpage = "" }
		print "<TR>\n<TD VALIGN=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"6\ height=\"1\"></TD><TD CLASS=\"text\">The search found $rows studies with search term \"$searchterm.\" $study_count studies searched. $onpage</TD>\n</TR>\n";
		}
		while(my $results = $sth->fetchrow_arrayref) {
			if (($counter > $low) && ($counter <= $high)) {
			my $description = @$results[2] . "...";
			print "<TR>\n<TD VALIGN=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"6\" height=\"1\"></TD><TD CLASS=\"text\">$counter. <A HREF=\"public_show_study.pl?id=@$results[0]\" CLASS=\"body\">@$results[1]</A><BR>Description: $description</TD>\n</TR>";
			}
			$counter++;
		}
}

print "<TR><TD VALIGN=\"top\"><img src=\"../../../../images/spacer.gif\" width=\"6\ height=\"1\"></TD>\n<TD CLASS=\"text\">";

&PrevNext($rows, $searchterm);

print "</TD></TR>\n";

print "<TR>\n<TD HEIGHT=\"25\"><img src=\"../../../../images/spacer.gif\" width=\"1\" height=\"1\"></TD></TR>";

$sth->finish || die("Could not finish study select: $DBI::errstr");

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print "</TABLE>\n";

&Footer;

print $query->end_html;

sub PrevNext {
my $rows = shift(@_);
my $searchterm = shift(@_);
my $i;
my $p = 1;
if ($rows > 5) {
	print "Go to page: ";
	for ($i = 0; $i < $rows; $i += 5) {
		print "<a href=\"public_search_study.pl?search_term=$searchterm&p=$p\" class=\"body\">$p</a>\n";
		$p++;
		}
	}

} # end sub PrevNext
