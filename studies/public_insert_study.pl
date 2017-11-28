#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include_cri.lib";

my $query = new CGI;

# Get the data into variables
my $study_name = $query->param('study_name');
$study_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters
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
$description =~ s/(\;|\>|\<|\||\\f\r)//gi;      # Newline allowed to maintain formatting
my $participate_who = quotemeta($query->param('participate_who'));
$participate_who =~ s/(\;|\>|\<|\||\\f\r)//gi;  # Newline allowed to maintain formatting
my $participate_what = quotemeta($query->param('participate_what'));
$participate_what =~ s/(\;|\>|\<|\||\\f\r)//gi; # Newline allowed to maintain formatting


# Set the variables for connecting to the database
[DELETED]

# Insert the data
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
	print $query->header;

	# Start building the Web page
	&Header;

	print "<TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"4\" CELLSPACING=\"4\">\n";
	print "<TR><TD CLASS=\"text\">We're sorry. It appears that your study identification number already exists in the database. Study ID numbers should be unique to each study. Please check your information and try again. If you need help, please email <a href=\"mailto:crp\@vmresearch.org\" class=\"body\">cpr\@vmresearch.org</a> or call 206-583-6579.\n";
	print "<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p></TD></TR>\n";
	print "</TABLE>\n";

	# Build the bottom of the page
	&Footer;

	print $query->end_html;

	$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
	$sth->execute || die("Could not unlock tables::$DBI::errstr");
	$sth->finish;

	$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

	} else {

	$sth = $dbh->prepare("INSERT INTO study VALUES ( NULL, '$study_id', '$study_name', '$pi_last_name', '$pi_first_name', '$pi_email', '$pi_phone', '$sc_last_name', '$sc_first_name', '$sc_email', '$sc_phone', '$description', '$participate_who', '$participate_what', '$accepting', '$category', 'No', NOW() )") || die("Could not insert category: $DBI::errstr");
	$sth->execute || die("Could not execute category insertion: $DBI::errstr");
	$sth->finish || die("Could not finish category insertion: $DBI::errstr");

	$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
	$sth->execute || die("Could not unlock tables::$DBI::errstr");
	$sth->finish;

	$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

	# Notification email

	# First, strip the escape forward slashes from the description
	$description =~ s/\\//g;
	$sc_last_name =~ s/\\//g;

	# Send the mail
	$ENV{"PATH"} = "/bin";  # Set environment path to allow system call
	open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");

	print MAIL "To: jwest\nFrom: BRI Web Site <crp\@vmresearch.org>\nReply-To: BRI Clinical Research Program <jwest\@vmresearch.org>\n";
	print MAIL "Subject: Study Added to the BRI Studies Public Database!\n";
	print MAIL "\nThe following study has been added to the BRI Studies public database:\n$study_name\n\nStudy ID:\n$study_id\n\nStudy Description:\n$description\n\nStudy Coordinator: $sc_first_name $sc_last_name\nStudy Coordinator Email: $sc_email\n";
	print MAIL "\nFor more information, please see the database administrator.\n";
	close(MAIL);

	# This sends a notification email to the person submitting the study.
	# NOTE: This code is commented out because the box where this script sits won't send email outside BRI
	# open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");
	# print MAIL "To: $sc_first_name $sc_last_name <$sc_email>\nFrom: BRI Web Site <crp\@vmresearch.org>\nReply-To: BRI Clinical Research Program <crp\@vmresearch.org>\n";
	# print MAIL "Subject: Your BRI Study Submission\n";
	# print MAIL "\nThank you for your study submission. We will review it immediately. If you have any follow-up questions or concerns, please contact us at 206-583-6579, or reply to this email.\n\n";
	# close(MAIL);

	# Redirect to another page to prevent multiple submittals of the same data
	print $query->redirect("../../../../cr_investigators/insert_ok.shtml");

	} # end if statement related to whether study id already exists or not
