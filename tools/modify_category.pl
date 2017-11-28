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
my $category = $query->param('category');
$category =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters
my $description = $query->param('description');
$description =~ s/(\;|\>|\<|\||\\n\f\r)//gi;
$description = quotemeta($description);
my $delete = $query->param('delete');



# Set the variables for connecting to the database
[DELETED]

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

# Start building the Web page
print $query->header;
print $query->start_html(-title=>'BRI Studies Database Tools', -style=>$styles);

# Print the tools navigation links
&ToolsNav;

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

my $sth = $dbh->prepare("LOCK TABLES category WRITE") || die("Could not lock tables::$DBI::errstr");
$sth->execute || die("Could not lock tables::$DBI::errstr");
$sth->finish;

if ($delete eq "Yes") {
	my $sth = $dbh->prepare("UPDATE category SET display = 'No' WHERE (id = $id)") || die("Could not delete category: $DBI::errstr");
	$sth->execute || die("Could not execute category deletion: $DBI::errstr");
	$sth->finish || die("Could not finish category deletion: $DBI::errstr");
	print "<CENTER>\n<H3 CLASS=\"title\">Category <I>$category</I> deleted successfully!</H3>\n</CENTER>";
	} else {
	my $sth = $dbh->prepare("UPDATE category SET name = '$category', description = '$description' WHERE (id = $id)") || die("Could not update category: $DBI::errstr");
	$sth->execute || die("Could not execute category update: $DBI::errstr");
	$sth->finish || die("Could not finish category update: $DBI::errstr");
	print "<CENTER>\n<H3 CLASS=\"title\">Category <I>$category</I> modified successfully!</H3>\n</CENTER>";
}

$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
$sth->execute || die("Could not unlock tables::$DBI::errstr");
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print $query->end_html;
