#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Get the study id from the "select study" form
my $id = $query->param('id');

# Set the variables for connecting to the database
[DELETED]

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the study data

my $sth = $dbh->prepare("SELECT * FROM study WHERE id = $id") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");

my ($discarded, $study_id, $study_name, $pi_last_name, $pi_first_name, $pi_email, $pi_phone, $sc_last_name, $sc_first_name, $sc_email, $sc_phone, $description, $participate_who, $participate_what, $accepting, $category, $display, $last_modified) = $sth->fetchrow;

$sth->finish;

# Get the category information for the form
my @category_ids = ('0');
my %categories = ( 0 => '-- Select One --' );
$sth = $dbh->prepare("SELECT id, name FROM category WHERE display = 'Yes' ORDER BY name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
while(my($catid, $name) = $sth->fetchrow) {
	push(@category_ids, $catid); # Build the category ids array
	$categories{$catid} = $name; # Build the categories hash
	}
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Variables for "accepting" form element.
my @accepting_values = ('Yes', 'No');
my %accepting_labels = ('Yes' => 'Yes', 'No' => 'No');

# Variables for "display study" form element.
my @display_values = ('Yes', 'No');
my %display_labels = ('Yes' => 'Yes', 'No' => 'No');

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
&AddStudyInstruct;

print $query->start_multipart_form(-action=>'modify_study.pl', -name=>'addstudyForm', -onSubmit=>'return checkaddstudyForm(this)');
print $query->hidden(-name=>'id', -default=>$id);

print "\n<TABLE WIDTH=\"700\" BORDER=\"1\" CELLPADDING=\"2\" CELLSPACING=\"0\">\n";

print "<TR>\n<TD VALIGN=\"MIDDLE\" ALIGN=\"CENTER\" COLSPAN=\"2\">";
print "<SPAN CLASS=\"title\">BRI Study Modification Form</SPAN><SPAN CLASS=\"copy\"> -- Record last modified: $last_modified<BR>\n";
print "Show study on Web site?&nbsp;</SPAN>";
print $query->scrolling_list(-name=>'display',
                                -value=>[@display_values], # List
                                -default=>[$display],
                                -size=>1,
                                -labels=>\%display_labels); # Hash

print "</TD></TR>\n";

print "<TR>\n<TD CLASS=\"copy\" VALIGN=\"TOP\">";
print "<B>Study Name:&nbsp;</B>";
print $query->textfield(-name=>'study_name', -default=>$study_name, -size=>30, -maxlength=>255);
print "<B>&nbsp;&nbsp;Study ID:&nbsp;</B> $study_id";
print $query->hidden(-name=>'study_id', -default=>$study_id);
print "<BR><I>Name example: \"Genetics of Kidneys in Diabetes (GokinD)\". Use lay terms and keywords.</I>";
print "</TD><TD CLASS=\"copy\" VALIGN=\"MIDDLE\">\n";
print "<B>Category:&nbsp;</B>";
print $query->scrolling_list(-name=>'category',
				-value=>[@category_ids], # List
				-default=>[$category],
				-size=>1,
				-labels=>\%categories); # Hash 
print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Currently accepting patient participants?&nbsp;</B>";
print $query->scrolling_list(-name=>'accepting',
				-value=>[@accepting_values], # List
				-default=>[$accepting],
				-size=>1,
				-labels=>\%accepting_labels); # Hash
print "<BR><I>Web visitors will be asked to read the study description and contact the study coordinator if they are interested in participating.</I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Principal Investigator</B><BR>Last name:&nbsp;";
print $query->textfield(-name=>'pi_last_name', -default=>$pi_last_name, -size=>30, -maxlength=>50);
print "&nbsp;&nbsp;First name:&nbsp;";
print $query->textfield(-name=>'pi_first_name', -default=>$pi_first_name, -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Principal Investigator Contact Information</B><BR>Email:&nbsp;";
print $query->textfield(-name=>'pi_email', -default=>$pi_email, -size=>30, -maxlength=>75);
print "&nbsp;&nbsp;Phone:&nbsp;";
print $query->textfield(-name=>'pi_phone', -default=>$pi_phone, -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Study Coordinator</B><BR>Last name:&nbsp;";
print $query->textfield(-name=>'sc_last_name', -default=>$sc_last_name, -size=>30, -maxlength=>50);
print "&nbsp;&nbsp;First name:&nbsp;";
print $query->textfield(-name=>'sc_first_name', -default=>$sc_first_name, -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Study Coordinator Contact Information</B><BR>Email:&nbsp;";
print $query->textfield(-name=>'sc_email', -default=>$sc_email, -size=>30, -maxlength=>75);
print "&nbsp;&nbsp;Phone:&nbsp;";
print $query->textfield(-name=>'sc_phone', -default=>$sc_phone, -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Describe the study.</B><BR>\n";
print $query->textarea(-name=>'description',
		       -default=>$description,
		       -rows=>3,
		       -columns=>50,
		       -wrap=>'hard',
		       -onKeyDown=>'wordCounter(this.form.description,this.form.remLen,100)',
		       -onKeyUp=>'wordCounter(this.form.description,this.form.remLen,100)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen', -size=>3, -default=>'100');
print "<BR><I>Please limit description to 100 words, and mention how this research could affect people with the disease. Example: The Juvenile Diabetes Research Foundation International is sponsoring the Genetics of Kidneys in Diabetes study to learn more about the role that genes play in causing kidney disease (nephropathy) in people with Type I diabetes.</I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>Who can participate?</B><BR>\n";
print $query->textarea(-name=>'participate_who',
		       -default=>$participate_who,
		       -rows=>5,
		       -columns=>50,
		       -wrap=>'hard',
		       -onKeyDown=>'wordCounter(this.form.participate_who,this.form.remLen2,200)',
		       -onKeyUp=>'wordCounter(this.form.participate_who,this.form.remLen2,200)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen2', -size=>3, -default=>'200');
print "<BR><I>Please limit this description to 200 words. Bulleted lists are helpful. Example:<BR><LI>People ages 18-54, who have had Type I diabetes for at least 15 years and do not have diabetes kidney disease</LI><LI>People ages 18-54, who have had Type I diabetes for at least 10 years and who also have diabetes kidney disease</LI><LI>Both parents will also be asked to join the study. Parents either may or may not have diabetes or nephropathy.</LI></I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\">";
print "<B>What do I have to do as a participant?</B><BR>\n";
print $query->textarea(-name=>'participate_what',
		       -default=>$participate_what,
		       -rows=>5,
		       -columns=>50,
		       -wrap=>'hard',
		       -onKeyDown=>'wordCounter(this.form.participate_what,this.form.remLen3,300)',
		       -onKeyUp=>'wordCounter(this.form.participate_what,this.form.remLen3,300)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen3', -size=>3, -default=>'300');
print "<BR><I>Please limit this description to 300 words. Example: If eligible, you will be asked to come to Virginia Mason Medical Center to complete some questionnaires and provide a blood and urine sample. These samples will be stored at the Centers for Disease Control (CDC) with samples from other participants in the GokinD study. They will be made available to researchers to conduct investigations into the role that genes play in kidney disease, as it is associated with Type I diabetes.</I>";
print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\" ALIGN=\"center\">";
print $query->submit(-name=>'submit', -value=>'Submit');
print "</TD>\n</TR>\n</TABLE>\n";

print $query->endform;

print $query->end_html;
