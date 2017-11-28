#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the new category name into a variable
my $new_category = $query->param('new_category');

# Set the variables for connecting to the database
[DELETED]

# Set up a counter for the forms
my $counter = 0;

# Start building the Web page
print $query->header;

# Create the "$jscript" variable for the javascript. See include.lib
my $jscript = &CheckForm;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -script=>$jscript, -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<CENTER><BR><TABLE WIDTH=\"400\" CELLPADDING=\"1\" CELLSPACING=\"1\">\n";
print "<TR><TD VALIGN=\"top\" align=\"center\"><SPAN CLASS=\"title\">Modify category names and descriptions.</SPAN></TD></TR>\n";
print "<TR><TD VALIGN=\"top\" align=\"center\"><HR WIDTH=\"500\"><BR></TD></TR>\n";

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

my $sth = $dbh->prepare("SELECT id, name, description FROM category WHERE (display = 'Yes') ORDER BY name") || die("Could not select from category: $DBI::errstr");
$sth->execute || die("Could not execute category select: $DBI::errstr");

my($id, $name, $description);
while(($id, $name, $description) = $sth->fetchrow) {
	my $form = "myForm" . $counter;
	print "<TR>\n";
	print $query->start_multipart_form(-action=>'modify_category.pl', -name=>$form, -onSubmit=>'return checkaddcatForm(this)');
	print "\n<TD VALIGN=\"top\">";
	print $query->hidden(-name=>'id',-default=>$id);
	print "\n<SPAN CLASS=\"copy\">Name:&nbsp;</SPAN>";
	print $query->textfield(-name=>'category', -default=>$name, -size=>30, -maxlength=>50);
	print "</TD></TR>\n";
	print "<TR><TD VALIGN=\"top\"><SPAN CLASS=\"copy\">Description:&nbsp;</SPAN><br>";
	print $query->textarea(-name=>'description',
				-default=>$description,
				-rows=>3,
		       		-columns=>50,
		       		-wrap=>'soft',
				-onKeyDown=>'wordCounter(this.form.description,this.form.remLen,100)',
				-onKeyUp=>'wordCounter(this.form.description,this.form.remLen,100)');
	print "<BR><SPAN CLASS=\"copy\">Please limit your description to 100 words.  Words remaining:&nbsp;</span>";
	print $query->textfield(-name=>'remLen', -size=>3, -default=>'100');
	print "<BR><SPAN CLASS=\"copy\">Delete?</SPAN>";
	print "<INPUT TYPE=\"checkbox\" NAME=\"delete\" VALUE=\"Yes\" onClick=\"confirmDelete(this.checked)\">\n\n";
	print "</TD></TR>\n";
	print "<TR><TD VALIGN=\"top\" align=\"center\">";
	print $query->submit(-name=>'submit', -value=>'Submit');
	print "\n";
	print $query->end_form;
	print "</TD></TR>\n";
	print "<TR><TD VALIGN=\"top\" align=\"center\"><HR WIDTH=\"500\"><BR></TD></TR>\n";
	$counter++;
}

$sth->finish || die("Could not finish category select: $DBI::errstr");

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

print "</TABLE><BR></CENTER>\n";

print $query->end_html;
