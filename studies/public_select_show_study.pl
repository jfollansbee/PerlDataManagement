#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include_clinical_research.lib";

my $query = new CGI;

my $id = $query->param('id');
$id =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters

# Set the variables for connecting to the database
[DELETED]

# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Set up category variables
my @category_ids = ('0');
my %categories = ( 0 => '-- Select One --' );

# Get the category data for the drop-down menu
my $sth = $dbh->prepare("SELECT id, name FROM category WHERE display = 'Yes' ORDER BY name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($cat_id, $name);
while(($cat_id, $name) = $sth->fetchrow) {
        push(@category_ids, $cat_id); # Build the category ids array
        $categories{$cat_id} = $name; # Build the categories hash
        }
$sth->finish;

# Get the study data
$sth = $dbh->prepare("SELECT * FROM study WHERE id = $id") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my ($discarded, $study_id, $study_name, $pi_last_name, $pi_first_name, $pi_email, $pi_phone, $sc_last_name, $sc_first_name, $sc_email, $sc_phone, $description, $participate_who, $participate_what, $accepting, $category, $display, $last_modified) = $sth->fetchrow;
$sth->finish;

# Get the category name for the study data
$sth = $dbh->prepare("SELECT name FROM category WHERE id = $category") || die("Could not start select for category name: $DBI::errstr");
$sth->execute || die("Could not select for category name: $DBI::errstr");
my $category_name = $sth->fetchrow;
$sth->finish;

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
print "<TR><TD CLASS=\"text\" VALIGN=\"top\">\n";

print "<br><p><span class=\"main\">Study Name: </span>$study_name<br><span class=\"main\">Category: </span>$category_name</p>\n";
print "<p><span class=\"main\">Currently accepting participants?</span> ";
if ($accepting eq 'Yes') {
	print "<i>Yes - please read the description below and contact the study coordinator if you are interested.</i></p>\n";
	} else {
	print "<i>Not at this time.</i></p>\n";
	}
print "<p><span class=\"main\">Principal Investigator: </span>$pi_first_name $pi_last_name<br>";
print "<span class=\"main\">Study Coordinator:</span> $sc_first_name $sc_last_name<br>";
print "<span class=\"main\">Phone:</span> $sc_phone<br><span class=\"main\">Email:</span> <a href=\"mailto:$sc_email\" class=\"body\">$sc_email</a></p>";
print "<p><span class=\"main\">What is the $study_name study?</span><pre>$description</pre></p>\n";
print "<p><span class=\"main\">Who can participate?</span><pre>$participate_who</pre></p>\n";
print "<p><span class=\"main\">What do I have to do as a study participant?</span><pre>$participate_what</pre></p>\n";
print "<span class=\"main\">Other studies in this category include:</span><br>(Studies highlighted are currently accepting participants.)<br><br>\n";

$sth = $dbh->prepare("SELECT id, study_name, accepting FROM study WHERE ((category = $category) && (display = 'Yes')) ORDER BY study_name") || die("Could not select from study: $DBI::errstr");
$sth->execute || die("Could not execute study select: $DBI::errstr");
my $rows = $sth->rows;
# If there's only one study, don't repeat the listing. Else show all other studies in this category
if ($rows == 1) {
	print "<i>No other studies in this category.</i><br>\n";
	} else {
	while(my $results = $sth->fetchrow_arrayref) {
		if (@$results[0] != $id) {
			if (@$results[2] eq 'Yes') {
				print "<a href=\"public_select_show_study.pl?id=@$results[0]\" class=\"body\" style=\"background-color: #ffff66\">@$results[1]</a><BR>\n";
				} else {
				print "<a href=\"public_select_show_study.pl?id=@$results[0]\" class=\"body\">@$results[1]</a><BR>\n";
				}
			}
		}
	}
$sth->finish || die("Could not finish study select: $DBI::errstr");

print "<p>Not finding what you're looking for? Use the search box to the left to search the studies database.</p>";
print "<br></TD></TR>";
print "</TABLE>\n";

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Add the bottom
&Footer;
