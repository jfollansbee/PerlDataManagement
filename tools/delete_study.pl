#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Time::localtime;
require "/var/www/cgi-bin/tools/include.lib";

# Get today's date
my $tm = localtime;
my ($day, $month, $year) = ($tm->mday, ($tm->mon + 1), ($tm->year + 1900));

my $query = new CGI;

# Get the study id from the "select study" form
my $id = $query->param('id');

# Set the variables for connecting to the database
[DELETED]

# Create some lists
my @months = ('1','2','3','4','5','6','8','9','10','11','12');
my @days = ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','26','27','28','29','30','31');
my @years = ('2002','2003','2004','2005','2006','2007'); 

# Start building the Web page
print $query->header;

# Create the "$jscript" variable for the javascript. See include.lib
my $jscript = &CheckForm;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -script=>$jscript, -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<BR>\n";

# Print the form instructions
print "<H3 CLASS=\"title\">Online Study Modification Form</H3>\n";
print "\n<TABLE WIDTH=\"700\" BORDER=\"1\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";
print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\">";
print "To delete a study or change the enrollment status, please complete and submit this form.<BR><BR>To make changes to the study description, you must contact Jeff West at <A HREF=\"mailto:jwest\@vmresearch.org\">jwest\@vmresearch.org</A> or 206-583-6579.\n";
print "</TD>\n</TR>\n</TABLE>\n";

print $query->start_multipart_form(-action=>'delete_study_send.pl', -name=>'deletestudyForm', -onSubmit=>'return checkdeletestudyForm(this)');

print "\n<TABLE WIDTH=\"700\" BORDER=\"1\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\">";
print "<B>Date of Request:&nbsp;</B>";
print $query->popup_menu(-name=>'request_month', -values=>\@months, -size=>1, -default=>$month);
print "&nbsp;";
print $query->popup_menu(-name=>'request_day', -values=>\@days, -size=>1, -default=>$day);
print "&nbsp;";
print $query->popup_menu(-name=>'request_year', -values=>\@years, -size=>1, -default=>$year);
print "<BR>In most cases, modifications will be made online by the end of the second business day following receipt of the request.\n";
print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\">";
print "<B>Requestor:</B><BR>First Name:&nbsp;";
print $query->textfield(-name=>'requestor_first_name', size=>30, maxlength=>50);
print "&nbsp;Last Name:&nbsp;";
print $query->textfield(-name=>'requestor_last_name', size=>30, maxlength=>50);
print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\">";
print "<B>Contact Info:</B><BR>Phone:&nbsp;";
print $query->textfield(-name=>'requestor_phone', size=>30, maxlength=>50);
print "&nbsp;Email:&nbsp;";
print $query->textfield(-name=>'requestor_email', size=>30, maxlength=>50);
print "</TD>\n</TR>\n";

# Get the study names and numbers
my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the study names for the form

my @study_list = ('0');
my %study_list = ( 0 => '-- Select One --' );
$dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");
my $sth = $dbh->prepare("SELECT study_name, study_id FROM study ORDER BY study_name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($study_name, $study_id, $study_item, @study_ids);
while(($study_name, $study_id) = $sth->fetchrow) {
	push(@study_ids, $study_id);			# Create a list of study ids for "enrollment" area
	$study_item = ($study_name . ', ' . $study_id);	# Create a study listing
	push(@study_list, $study_item);			# Build the select box values for "DELETED" area
	$study_list{$study_item} = $study_item;		# Build the select box listings for "DELETED" area
        }
$sth->finish;

$dbh->disconnect;

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\" NOWRAP>";
print "<B>Studies to be DELETED</B><BR>\n";

# Create the "DELETED" area drop-down boxes
my ($counter, $i);
$counter = 4;

for ($i = 0; $i <= 4; $i++) {
print $query->scrolling_list(-name=>'delete_study' . $i,
                             -value=>[@study_list], # List
                             -default=>['0'],
                             -size=>1,
                             -labels=>\%study_list); # Hash
print "<BR>\n";
} # end for loop

print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"left\" NOWRAP>";
print "<B>Studies with changed enrollment status</B> Select a study and an enrollment status.<BR>\n";

# Create the enrollment area drop-down boxes
for ($i = 0; $i <= 4; $i++) {
print $query->scrolling_list(-name=>'change_enrollment' . $i,
                             -value=>[@study_list], # List
                             -default=>['0'],
                             -size=>1,
                             -labels=>\%study_list); # Hash

print "<INPUT TYPE=\"radio\" NAME=\"change_status$i\" VALUE=\"Accepting\">Accepting\n";
print "<INPUT TYPE=\"radio\" NAME=\"change_status$i\" VALUE=\"Not accepting\">Not accepting\n";

print "<BR>\n";
} # end for loop

print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" ALIGN=\"center\">";
print $query->submit(-name=>'submit', -value=>'Submit');
print "</TD>\n</TR>\n</TABLE>\n";

print $query->endform;

print $query->end_html;

