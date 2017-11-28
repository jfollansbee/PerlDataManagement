#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Set the variables for connecting to the database
[DELETED]

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the study names for the form
my @ids = ('0');	# This is for the database record id, NOT the study id used in the "add study" form
my %study_names = ( 0 => '-- Select One --' );
$dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");
my $sth = $dbh->prepare("SELECT id, study_name FROM study ORDER BY study_name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($id, $study_name);
while(($id, $study_name) = $sth->fetchrow) {
        push(@ids, $id); # Build the database record ids array
        $study_names{$id} = $study_name; # Build the categories hash
        }
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Start building the Web page
print $query->header;

# Create the "$jscript" variable for the javascript. See include.lib
my $jscript = &CheckForm;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -script=>$jscript, -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<CENTER><H3 CLASS=\"title\">Modify a Study in the Database</H3></CENTER>\n";

print "<BR><TABLE WIDTH=\"700\" BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";

print "<TR>\n<TD CLASS=\"copy\">";

print $query->start_multipart_form(-action=>'show_study.pl', -name=>'selectStudy', -onSubmit=>'return checkselectstudyForm(this)');
print "Study Name:&nbsp;";
print $query->scrolling_list(-name=>'id',
			     -value=>[@ids], # List
			     -default=>['0'],
			     -size=>1,
			     -labels=>\%study_names); # Hash
print $query->submit(-name=>'go', -value=>'Go');
print $query->endform;

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\">";

print $query->start_multipart_form(-action=>'search_study.pl', -name=>'searchStudy', -onSubmit=>'return checksearchForm(this)');
print "Search Studies:&nbsp;";
print $query->textfield(-name=>'search_term', -size=>30, -maxlength=>50);
print "&nbsp;";
print $query->submit(-name=>'search', -value=>'Search');
print $query->endform;

print "</TD>\n</TR>\n</TABLE>\n";

print $query->end_html;
