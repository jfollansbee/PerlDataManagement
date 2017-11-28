#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include.lib";

my $query = new CGI;

# Get the study id from the "select study" form
my $id = $query->param('id');

# Set the variables for connecting to the database
[DELETED]

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the study data
my $sth = $dbh->prepare("SELECT * FROM study WHERE id = $id") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my ($discarded, $study_id, $study_name, $pi_last_name, $pi_first_name, $pi_email, $pi_phone, $sc_last_name, $sc_first_name, $sc_email, $sc_phone, $description, $participate_who, $participate_what, $accepting, $category, $display, $last_modified) = $sth->fetchrow;
$sth->finish;

# Get the category name 
$sth = $dbh->prepare("SELECT name FROM category WHERE id = $category") || die("Could not start select for category name: $DBI::errstr");
$sth->execute || die("Could not select for category name: $DBI::errstr");
my $category_name = $sth->fetchrow;
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Start building the Web page
print $query->header;

# Start building the Web page
&Header;

print "\n<TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";

print "<TR><TD VALIGN=\"top\" rowspan=\"7\"><img src=\"../../../../images/spacer.gif\" width=\"16\ height=\"1\"></TD><TD COLSPAN=\"2\" height=\"1\"><img src=\"../../../../images/spacer.gif\" width=\"1\ height=\"1\"></TD></TR>";

print "<TR>\n<TD VALIGN=\"TOP\" CLASS=\"text\">";
print "<span class=\"main\">Study Name:</span> $study_name</span>";
print "<BR><span class=\"main\">Category:</span> $category_name<BR><BR>";
print "</TD></TR>";
print "\n<TR>\n<TD CLASS=\"text\">";

print "<span class=\"main\">Currently accepting participants?</span> ";
if ($accepting eq 'Yes') {
        print "<i>Yes - please read the description below and contact the study coordinator if you are interested.</i>\n";
        } else {
        print "<i>Not at this time.</i>\n";
        }

print "<BR><BR></TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<span class=\"main\">Principal Investigator:</span> $pi_first_name $pi_last_name<BR>";
print "<span class=\"main\">Study Coordinator:</span> $sc_first_name $sc_last_name<BR>";
print "<span class=\"main\">Phone:</span> $sc_phone<BR><span class=\"main\">Email:</span> <a href=\"mailto:$sc_email\" class=\"body\">$sc_email</a><BR><BR>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<span class=\"main\">What is the $study_name study?</span><pre>$description</pre>\n";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<span class=\"main\">Who can participate?</span><pre>$participate_who</pre>\n";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<span class=\"main\">What do I have to do as a participant?</span><pre>$participate_what</pre>\n";
print "</TD>\n</TR>\n";

print "</TABLE>\n";

# Add the Footer
&Footer;

print $query->end_html;
