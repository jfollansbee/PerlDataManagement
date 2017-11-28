#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
require "/var/www/cgi-bin/studies/include_cri.lib";

my $query = new CGI;

# Set the variables for connecting to the database
[DELETED]

my $dbh = DBI->connect("DBI:mysql:$database", $username, $password) || die("Can't open database: $DBI::errstr");

# Get the category information for the form
my @category_ids = ('0');
my %categories = ( 0 => '-- Select One --' );
my $sth = $dbh->prepare("SELECT id, name FROM category WHERE display = 'Yes' ORDER BY name") || die("Could not start select: $DBI::errstr");
$sth->execute || die("Could not select::$DBI::errstr");
my($id, $name);
while(($id, $name) = $sth->fetchrow) {
        push(@category_ids, $id); # Build the category ids array
        $categories{$id} = $name; # Build the categories hash
        }
$sth->finish;

$dbh->disconnect || die("Could not disconnect: $DBI::errstr");

# Variables for "accepting" form element.
my @accepting_values = ('Yes', 'No');
my %accepting_labels = ('Yes' => 'Yes', 'No' => 'No');

print $query->header;

# Create the "$jscript" variable for the javascript. See include_cri.lib
# my $jscript = &CheckForm;

# Start building the Web page
&Header;

# Print the form checking javascript
&CheckForm;

# Print the form instructions
&AddStudyInstruct;

# Now build the form
print "<TABLE WIDTH=\"380\" BORDER=\"0\" CELLPADDING=\"4\" CELLSPACING=\"4\">\n";

print $query->start_multipart_form(-action=>'public_insert_study.pl', -name=>'addstudyForm', -onSubmit=>'return checkaddstudyForm(this)');


print "<TR>\n<TD CLASS=\"text\">";
print "<B>Study Name:&nbsp;</B>";
print $query->textfield(-name=>'study_name', -size=>30, -maxlength=>255);
print "<BR><I>Name example: &quot;Genetics of Kidneys in Diabetes (GokinD).&quot; Use lay terms and keywords.</I>";
print "</TD></TR>\n<TR><TD CLASS=\"text\"><B>Study ID:&nbsp;</B>";
print $query->textfield(-name=>'study_id', -size=>10, -maxlength=>15);
print "</TD></TR>";
print "\n<TR><TD CLASS=\"text\">\n";
print "<B>Category:&nbsp;</B>";
print $query->scrolling_list(-name=>'category',
                                -value=>[@category_ids], # List
                                -default=>['0'],
                                -size=>1,
                                -labels=>\%categories); # Hash
print "</TD></TR>\n<TR>\n<TD CLASS=\"text\" COLSPAN=\"2\">";
print "<B>Currently accepting patient participants?&nbsp;</B>";
print $query->scrolling_list(-name=>'accepting',
                                -value=>[@accepting_values], # List
                                -default=>['Yes'],
                                -size=>1,
                                -labels=>\%accepting_labels); # Hash
print "<BR><I>Web visitors will be asked to read the study description and contact the study coordinator if they are interested in participating.</I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Principal Investigator</B><BR>First name:&nbsp;";
print $query->textfield(-name=>'pi_first_name', -size=>30, -maxlength=>50);
print "<BR>Last name:&nbsp;";
print $query->textfield(-name=>'pi_last_name', -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Principal Investigator Contact Information</B><BR>Email:&nbsp;";
print $query->textfield(-name=>'pi_email', -size=>30, -maxlength=>75);
print "<BR>Phone:&nbsp;";
print $query->textfield(-name=>'pi_phone', -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Study Coordinator</B><BR>First name:&nbsp;";
print $query->textfield(-name=>'sc_first_name', -size=>30, -maxlength=>50);
print "<BR>Last name:&nbsp;";
print $query->textfield(-name=>'sc_last_name', -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Study Coordinator Contact Information</B><BR>Email:&nbsp;";
print $query->textfield(-name=>'sc_email', -size=>30, -maxlength=>75);
print "<BR>Phone:&nbsp;";
print $query->textfield(-name=>'sc_phone', -size=>30, -maxlength=>50);
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Describe the study.</B><BR>\n";
print $query->textarea(-name=>'description',
                       -rows=>3,
                       -columns=>50,
                       -wrap=>'hard',
                       -onKeyDown=>'wordCounter(this.form.description,this.form.remLen,100)',
                       -onKeyUp=>'wordCounter(this.form.description,this.form.remLen,100)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen', -size=>3, -default=>'100');
print "<BR><I>Please limit description to 100 words, and mention how this research could affect people with the disease. Example: The Juvenile Diabetes Research Foundation International is sponsoring the Genetics of Kidneys in Diabetes study to learn more about the role that genes play in causing kidney disease (nephropathy) in people with type I diabetes.</I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>Who can participate?</B><BR>\n";
print $query->textarea(-name=>'participate_who',
                       -rows=>5,
                       -columns=>50,
                       -wrap=>'hard',
                       -onKeyDown=>'wordCounter(this.form.participate_who,this.form.remLen2,200)',
                       -onKeyUp=>'wordCounter(this.form.participate_who,this.form.remLen2,200)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen2', -size=>3, -default=>'200');
print "<BR><I>Please limit this description to 200 words. Bulleted lists are helpful. Example:<BR><LI>People ages 18-54, who have had type I diabetes for at least 15 years and do not have diabetes kidney disease.</LI><LI>People ages 18-54, who have had type I diabetes for at least 10 years and who also have diabetes kidney disease.</LI><LI>Both parents will also be asked to join the study. Parents either may or may not have diabetes or nephropathy.</LI></I>";
print "</TD>\n</TR>\n";

print "</TD></TR>\n<TR>\n<TD CLASS=\"text\">";
print "<B>What do I have to do as a participant?</B><BR>\n";
print $query->textarea(-name=>'participate_what',
                       -rows=>5,
                       -columns=>50,
                       -wrap=>'hard',
                       -onKeyDown=>'wordCounter(this.form.participate_what,this.form.remLen3,300)',
                       -onKeyUp=>'wordCounter(this.form.participate_what,this.form.remLen3,300)');
print "<BR>Words remaining:&nbsp;";
print $query->textfield(-name=>'remLen3', -size=>3, -default=>'300');
print "<BR><I>Please limit this description to 300 words. Example: If eligible, you will be asked to come to Virginia Mason Medical Center to complete some questionnaires and provide a blood and urine sample. These samples will be stored at the Centers for Disease Control (CDC) with samples from other participants in the GokinD study. They will be made available to researchers to conduct investigations into the role that genes play in kidney disease, as it is associated with type I diabetes.</I>";
print "</TD>\n</TR>\n";

print "<TR>\n<TD CLASS=\"copy\" COLSPAN=\"2\" ALIGN=\"center\">";
print $query->submit(-name=>'submit', -value=>'Submit');
print "</TD>\n</TR>\n";

print $query->endform;

print "</TABLE>\n";

&Footer;

print $query->end_html;
