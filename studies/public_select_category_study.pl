#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include_clinical_research.lib";

my $query = new CGI;

my $category = $query->param('category');
$category =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters

# Set the variables for connecting to the database
[DELETED]

# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Set up category variables
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

$sth = $dbh->prepare("SELECT name, description FROM category WHERE id = $category") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($category_name, $description);
($category_name, $description) = $sth->fetchrow;
$sth->finish;

# Get the number of available studies
$sth = $dbh->prepare("SELECT COUNT(id) AS count FROM study WHERE display = 'Yes'") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");
my $study_count = $sth->fetchrow;
$sth->finish || die("Could not finish study select: $DBI::errstr");

print $query->header;

# Start building the Web page
&Header;

print "<br><TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";
print $query->start_multipart_form(-action=>'public_show_category_study.pl', -name=>'selectCategory', -onChange=>'return jumpPage(this.form.selectCategory)');
print "<TR><td valign=\"top\" rowspan=\"2\"><img src=\"../../../../images/spacer.gif\" width=\"15\" height=\"300\"></TD>\n";
print "<TD CLASS=\"text\" VALIGN=\"top\">\n";
print "Select another study category:&nbsp;";
print $query->scrolling_list(-name=>'category',
				-onchange=>'return jumpPage(this.form.category)',
                                -value=>[@category_ids], # List
                                -default=>['0'],
                                -size=>1,
                                -labels=>\%categories); # Hash
print "</TD></TR>\n";
print $query->end_form;
print "<TR><TD CLASS=\"text\" VALIGN=\"top\"><SPAN CLASS=\"main\">$category_name</SPAN><BR>$description<BR>\n";

# Since we use this in two places, put this stuff into a variable
my $contact = "To participate in a BRI clinical trial, please contact the study coordinator listed in each of the study links below, or send an e-mail to the <a href=\"mailto:crp\@vmresearch.org\" class=\"body\">Clinical Research Program</a>.<BR><BR><SPAN CLASS=\"main\">Studies highlighted below are currently accepting study participants.</SPAN> Please click on individual studies for more information.<BR><BR>";

$sth = $dbh->prepare("SELECT id, study_name, accepting FROM study WHERE ((category = $category) && (display = 'Yes')) ORDER BY study_name") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");
my $rows = $sth->rows;

if ($rows == 0) {
	print "<p>No studies currently listed. Please try another category. <!-- $study_count studies searched. --></p>\n";
	} elsif ($rows != 0) {
		if ($rows == 1) {
			print "<p>$contact <!-- One study found. $study_count studies searched. --><p>\n";
		} else {
			print "<p>$contact <!-- $rows studies found. $study_count studies searched. --></p>\n";
		}
		while(my $results = $sth->fetchrow_arrayref) {
			if (@$results[2] eq 'Yes') {
				print "<a href=\"public_select_show_study.pl?id=@$results[0]\" class=\"body\" style=\"background-color: #ffff66\">@$results[1]</a><BR>\n";

			} else {
				print "<a href=\"public_select_show_study.pl?id=@$results[0]\" class=\"body\".>@$results[1]</a><BR>\n";
			}
		}
	}

$sth->finish || die("Could not finish study select: $DBI::errstr");

print "<p>Not finding what you're looking for? Use the search box to the left to search the studies database.</p><p>&nbsp;</p>";
print "</TD></TR>";
print "</TABLE>\n";

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Add the bottom
&Footer;
