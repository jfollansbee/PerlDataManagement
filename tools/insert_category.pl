#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the new category name into a variable
my $category = $query->param('category');
$category =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters
my $description = $query->param('description');
$description =~ s/(\;|\>|\<|\||\\n\f\r)//gi;     # Remove dangerous characters

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

my $sth = $dbh->prepare("LOCK TABLES category WRITE") || die("Could not lock tables::$DBI::errstr");
$sth->execute || die("Could not lock tables::$DBI::errstr");
$sth->finish;

$sth = $dbh->prepare("INSERT INTO category VALUES ( NULL, '$category', '$description', 'Yes' )") || die("Could not insert category: $DBI::errstr");
$sth->execute || die("Could not execute category insertion: $DBI::errstr");
$sth->finish || die("Could not finish category insertion: $DBI::errstr");

$sth = $dbh->prepare("UNLOCK TABLES") || die("Could not unlock tables::$DBI::errstr");
$sth->execute || die("Could not unlock tables::$DBI::errstr");
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print "<CENTER>\n<H3 CLASS=\"title\">Category <I>$category</I> added successfully!</H3>\n</CENTER>";

print $query->end_html;
