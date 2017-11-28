#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the new category name into a variable
my $study_name = $query->param('study_name');
$study_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;	# Remove dangerous characters
my $study_id = $query->param('study_id');
$study_id =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $category = $query->param('category');
my $accepting = $query->param('accepting');
my $pi_last_name = quotemeta($query->param('pi_last_name'));
$pi_last_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_first_name = $query->param('pi_first_name');
$pi_first_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_email = $query->param('pi_email');
$pi_email =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_phone = $query->param('pi_phone');
$pi_phone =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_last_name = quotemeta($query->param('sc_last_name'));
$sc_last_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_first_name = $query->param('sc_first_name');
$sc_first_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_email = $query->param('sc_email');
$sc_email =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_phone = $query->param('sc_phone');
$sc_phone =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $description = quotemeta($query->param('description'));
$description =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Newline allowed to maintain formatting	
my $participate_who = quotemeta($query->param('participate_who'));
$participate_who =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Newline allowed to maintain formatting
my $participate_what = quotemeta($query->param('participate_what'));
$participate_what =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Newline allowed to maintain formatting

# Set the variables for connecting to the database
[DELETED]

# Start building the Web page
print $query->header;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -style=>$styles);

# Print the tools navigation links
&ToolsNav;

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

my $sth = $dbh->prepare("LOCK TABLES study WRITE") || die("Could not lock tables::$DBI::errstr");
$sth->execute || die("Could not lock tables::$DBI::errstr");
$sth->finish;

# Check if study id number already exists. We don't want duplicates in the database
my $count = 0;
$sth = $dbh->prepare("SELECT COUNT(study_id) AS count FROM study WHERE (study_id = '$study_id')") || die("Could not insert category: $DBI::errstr");
$sth->execute || die("Could not execute category insertion: $DBI::errstr");
$count = $sth->fetchrow;
$sth->finish || die("Could not finish category insertion: $DBI::errstr");

# If the study id exists, tell the user. Else insert the data and email CRP.
if ($count != 0) {

	$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
	$sth->execute || die("Could not unlock tables::$DBI::errstr");
	$sth->finish;

	$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

	print "<CENTER>\n<H3 CLASS=\"title\">We're sorry. The study ID <i>$study_id</i> already exists.<br>Please check your information and try again.</H3>\n</CENTER>";

	print $query->end_html;

	} else {

	$sth = $dbh->prepare("INSERT INTO study VALUES ( NULL, '$study_id', '$study_name', '$pi_last_name', '$pi_first_name', '$pi_email', '$pi_phone', '$sc_last_name', '$sc_first_name', '$sc_email', '$sc_phone', '$description', '$participate_who', '$participate_what', '$accepting', '$category', 'No', NOW() )") || die("Could not insert category: $DBI::errstr");
	$sth->execute || die("Could not execute category insertion: $DBI::errstr");
	$sth->finish || die("Could not finish category insertion: $DBI::errstr");

	$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
	$sth->execute || die("Could not unlock tables::$DBI::errstr");
	$sth->finish;

	$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

	print "<CENTER>\n<H3 CLASS=\"title\">Study <I>$study_name</I> added successfully!</H3>\n</CENTER>";

	print $query->end_html;

	# Notification email

	# First, strip the escape forward slashes from the description
	$description =~ s/\\//g;
	$sc_last_name =~ s/\\//g;

	# Send the mail
	$ENV{"PATH"} = "/bin";  # Set environment path to allow system call
	open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");

	print MAIL "To: jwest\nFrom: BRI Studies Database Editing Tools <jwest\@vmresearch.org>\nReply-To: BRI Studies Database Editing Tools <jwest\@vmresearch.org>\n";
	print MAIL "Subject: Study Added to the BRI Studies Public Database!\n";
	print MAIL "\nThe following study has been added to the BRI Studies public database:\n$study_name\n\nStudy ID: $study_id\n\nStudy Description:\n$description\n\nStudy Coordinator: $sc_first_name $sc_last_name\nStudy Coordinator Email: $sc_email\n";
	print MAIL "\nFor more information, please see the database administrator.\n";

	close(MAIL);

	} # end if/else statement related to check on whether study exists or not
