#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the new category name into a variable
my $id = $query->param('id');
my $study_name = $query->param('study_name');
$study_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;	# Remove dangerous characters
my $study_id = $query->param('study_id');
$study_id =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $category = $query->param('category');
my $accepting = $query->param('accepting');
my $pi_last_name = $query->param('pi_last_name');
$pi_last_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_first_name = $query->param('pi_first_name');
$pi_first_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_email = $query->param('pi_email');
$pi_email =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $pi_phone = $query->param('pi_phone');
$pi_phone =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_last_name = $query->param('sc_last_name');
$sc_last_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_first_name = $query->param('sc_first_name');
$sc_first_name =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_email = $query->param('sc_email');
$sc_email =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $sc_phone = $query->param('sc_phone');
$sc_phone =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
my $description = ($query->param('description'));
$description =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Allow newlines to maintain formatting
my $participate_who = ($query->param('participate_who'));
$participate_who =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Allow newlines to maintain formatting
my $participate_what = ($query->param('participate_what'));
$participate_what =~ s/(\;|\>|\<|\||\\f\r)//gi;	# Allow newlines to maintain formatting
my $display = $query->param('display');

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

my @columns = &GetColumns($dbh);

my @change = ($id, $study_id, $study_name, $pi_last_name, $pi_first_name, $pi_email, $pi_phone, $sc_last_name, $sc_first_name, $sc_email, $sc_phone, $description, $participate_who, $participate_what, $accepting, $category, $display);

# Get the current values from the table
$sth = $dbh->prepare("SELECT * FROM study WHERE id = $id") || die("Could not prepare query: $DBI::errstr");
$sth->execute || die("Could not execute query: $DBI::errstr");
my $rows = $sth->rows;
my @current = $sth->fetchrow_array;
$sth->finish || die("Could not finish query: $DBI::errstr");

# If new data differs from old data, update the database.
if ($rows > 0) {
	my $i;
	for ($i = 1; $i <= ($#columns - 1); $i++) {
		if ($change[$i] ne $current[$i]) { 
			$change[$i] = quotemeta($change[$i]); # Escape any special characters in the changed data
			my $sth = $dbh->prepare("UPDATE study SET $columns[$i] = '$change[$i]', last_modified = NOW() WHERE (id = $id)") || die("Could not start study table update: $DBI::errstr");
			$sth->execute || die("Could not update study table: $DBI::errstr");
			$sth->finish || die("Could not finish update of study table: $DBI::errstr");
		 	} 
		}
	} else {
		print "<SPAN CLASS=\"copy\">No data found in database. Abort update!</SPAN>";
}

$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
$sth->execute || die("Could not unlock tables::$DBI::errstr");
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print "<CENTER>\n<H3 CLASS=\"title\">Study <I>$study_name</I> modified successfully!</H3>\n</CENTER>";

print $query->end_html;
# Notification email

# Send the mail
$ENV{"PATH"} = "/bin";  # Set environment path to allow system call
open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");

print MAIL "To: jwest\nFrom: BRI Studies Database Editing Tools <jwest\@vmresearch.org>\nReply-To: BRI Studies Database Editing Tools <jwest\@vmresearch.org>\n";
print MAIL "Subject: Record in BRI Studies Database Modified!\n";
print MAIL "\nThe following study has been modified in the BRI Studies public database:\n$study_name\n\nStudy ID:\n$study_id\n\nStudy Description:\n$description\n\nStudy Coordinator: $sc_first_name $sc_last_name\nStudy Coordinator Email: $sc_email\n";
print MAIL "\nFor more information, please see the database administrator.\n";

close(MAIL);

# Puts table columns names into an array
sub GetColumns {
no strict 'refs'; # Suppresses an array reference error
my $dbh = shift(@_);
my @columns = ();
my $sth = $dbh->prepare("SHOW columns FROM study") || die("Could not show study columns: $DBI::errstr");
$sth->execute || die("Could not execute SHOW columns FROM study statement: $DBI::errstr");
my $get_columns = $sth->fetchall_arrayref || die("Could not get study column names: $DBI::errstr");
my($i,$j);
for $i (0..$#$get_columns) {
	for $j (0..$#$get_columns->[$i]) {
	push(@columns, ($get_columns->[$i][$j]));
	}
}
$sth->finish;
return(@columns);
} # end sub GetColumns
