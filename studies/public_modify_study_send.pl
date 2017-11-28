#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

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

# Put the data from the form into an array
my @change = ($id, $study_id, $study_name, $pi_last_name, $pi_first_name, $pi_email, $pi_phone, $sc_last_name, $sc_first_name, $sc_email, $sc_phone, $description, $participate_who, $participate_what, $accepting, $category, $display);

# Create an array of titles for use in the email notification
my @titles = ('Record ID:', 'Study ID:', 'Study Name:', 'PI Last Name:', 'PI First Name:', 'PI Email:', 'PI Phone:', 'SC Last Name:', 'SC First Name:', 'SC Email:', 'SC Phone:', 'Description:', 'Who Can Participate:', 'How to Participate:', 'Accepting?', 'Category:', 'Display:', 'Last Modified:');

# Create a hash that will hold all the requested changes.
my %request = ();

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the category information for the form
my @category_ids;
my %categories = ();
my $sth = $dbh->prepare("SELECT id, name FROM category WHERE display = 'Yes' ORDER BY name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($cat_id, $cat_name);
while(($cat_id, $cat_name) = $sth->fetchrow) {
        push(@category_ids, $cat_id); # Build the category ids array
        $categories{$cat_id} = $cat_name; # Build the categories hash
        }
$sth->finish;

# Get the column names
my @columns = &GetColumns($dbh);

# Get the current values from the table
$sth = $dbh->prepare("SELECT * FROM study WHERE id = $id") || die("Could not prepare query: $DBI::errstr");
$sth->execute || die("Could not execute query: $DBI::errstr");
my $rows = 0;
$rows = $sth->rows;
my @current = $sth->fetchrow_array;
$sth->finish || die("Could not finish query: $DBI::errstr");

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# If new data differs from old data, note the change.
my $error;
my $counter = 0;
if ($rows != 0) {
	my $i;
	for ($i = 1; $i <= ($#columns - 1); $i++) {
		if ($change[$i] ne $current[$i]) { 
			$request{$titles[$i]} = "$change[$i]" . "\n\n";
			$counter++;
		 	} 
		}
	}  else {
		$error = "ERROR: No data found for this record id.";
	}

# Redirect to another page to prevent multiple submittals of the same data
print $query->redirect("../../../../cr_investigators/insert_ok.shtml");

# Notification email

# Send the mail
$ENV{"PATH"} = "/bin";  # Set environment path to allow system call
open(MAIL, "|sendmsg") || die("Could not open sendmsg for emailing.");

print MAIL "To: jwest\nFrom: BRI Web Site <jwest\@vmresearch.org>\nReply-To: BRI Clinical Research Program <crp\@vmresearch.org>\n";
print MAIL "Subject: Study Modification Request from BRI Web Site\n";

print MAIL "\nA request has been submitted via the Web site to modify this study:\n\nStudy Name: $current[2]\n\nStudy ID: $current[1]\n\nStudy Coordinator: $current[8] $current[7]\n\nStudy Coordinator Email: $current[9]\n";

print MAIL "\n--- Requested changes follow ---\n\n";

if ($counter != 0) {
	# If the category has been changed, print it out.
	if (exists($request{'Category:'})) {
		my $cat = $request{'Category:'};
		my ($key, $value);
		while(($key, $value) = each(%categories)) {
			if ($cat == $key) {
				print MAIL "Category: $value\n\n";
				}
			}
		delete($request{'Category:'});
		}

	print MAIL join(" ", %request);

	} else {
		print MAIL "ERROR: No change request found. Please contact the study coordinator.\n";
	} # end if statement

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
