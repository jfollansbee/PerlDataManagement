#! /usr/bin/perl -wT

# This program sends the email created with the duplication request form

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

my $request_month = $query->param('request_month');
my $request_day = $query->param('request_day');
my $request_year = $query->param('request_year');
my $requestor_first_name = $query->param('requestor_first_name');
my $requestor_last_name = $query->param('requestor_last_name');
my $requestor_phone = $query->param('requestor_phone');
my $requestor_email = $query->param('requestor_email');
my $delete_study0 = $query->param('delete_study0');
my $delete_study1 = $query->param('delete_study1');
my $delete_study2 = $query->param('delete_study2');
my $delete_study3 = $query->param('delete_study3');
my $delete_study4 = $query->param('delete_study4');
my $change_enrollment0 = $query->param('change_enrollment0');
my $change_enrollment1 = $query->param('change_enrollment1');
my $change_enrollment2 = $query->param('change_enrollment2');
my $change_enrollment3 = $query->param('change_enrollment3');
my $change_enrollment4 = $query->param('change_enrollment4');
my $change_status0 = $query->param('change_status0');
my $change_status1 = $query->param('change_status1');
my $change_status2 = $query->param('change_status2');
my $change_status3 = $query->param('change_status3');
my $change_status4 = $query->param('change_status4');

# Build the HTML response
print $query->header;

# Get the styles into a variable and load them into the HTML
my $styles = &Styles;
print $query->start_html(-title=>'BRI Studies Database Editing Tools', -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<BR><CENTER><H3 CLASS=\"title\">Study modification request sent!</H3></CENTER>\n";

print $query->end_html;

$ENV{"PATH"} = "/bin";	# Set environment path to allow system call
open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");

my $requestor_name = $requestor_first_name . " " . $requestor_last_name;
my $request_date = $request_month . "-" . $request_day . "-" . $request_year;

print MAIL "To: jwest\nFrom: $requestor_name <$requestor_email>\nReply-To: $requestor_email\n";
print MAIL "Subject: Study Modification Request\n\n";
print MAIL "Request Date: $request_date\n";
print MAIL "Requestor: $requestor_name\n";
print MAIL "Phone: $requestor_phone\n";
print MAIL "Email: $requestor_email\n";

my @deletions = ($delete_study0, $delete_study1, $delete_study2, $delete_study3, $delete_study4);
my @change_enrollments = ($change_enrollment0, $change_enrollment1, $change_enrollment2, $change_enrollment3, $change_enrollment4);
my @change_statuses = ($change_status0, $change_status1, $change_status2, $change_status3, $change_status4);

print MAIL "Study Modification Requests:\n\n";

print MAIL "Deletions:\n\n";

my $i;
my $counter = 0;
foreach $i (@deletions) {
	if ($i ne "0") {
		print MAIL "\to $i\n";
		$counter++;
	}
} # end foreach loop

if ($counter == 0) { print MAIL "\tNo deletions requested.\n" }

print MAIL "\nEnrollment Changes:\n\n";

$counter = 0;
my $change_count = 0;
foreach $i (@change_enrollments) {
	if ($i ne "0") {
 		print MAIL "\to $i: $change_statuses[$change_count]\n";
		$counter++;
	}
	$change_count++;
} # end foreach loop

if ($counter == 0) { print MAIL "\tNo enrollment changes requested.\n" }

print MAIL "\nEnd modification request.\n";

print MAIL "\nAn acknowledgement of this request has been sent to the requestor.\n";

close(MAIL);

open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");
print MAIL "To: $requestor_email\nFrom: Jeff West <jwest>\nReply-To: jwest\@vmresearch.org\n";
print MAIL "Subject: Your Study Modification Request\n";
print MAIL "\nThank you for your study modification request. We will post the change by the end of the second business day following the request. If you have any follow-up questions or concerns, please me at 206-583-6579.\n\n";
print MAIL "Jeff West\n";
close(MAIL);
