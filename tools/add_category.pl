#! /usr/bin/perl -wT

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
require "/var/www/cgi-bin/tools/include.lib";

my $query = new CGI;

# Start building the Web page
print $query->header;

# Create the "$jscript" variable for the javascript. See include.lib
my $jscript = &CheckForm;

# Create the "$styles" variable for the stylesheet. See include.lib
my $styles = &Styles;

print $query->start_html(-title=>'BRI Studies Database Editing Tools', -script=>$jscript, -style=>$styles);

# Print the tools navigation links
&ToolsNav;

print "<CENTER>\n<H3 CLASS=\"title\">Add A Category to the Database</H3>\n";

print $query->start_multipart_form(-action=>'insert_category.pl',
				   -name=>'myForm',
				   -onSubmit=>'return checkaddcatForm(this)');

print "<SPAN CLASS=\"copy\">Please enter a new category name.</BR>Be sure to check your spelling!<BR><BR></SPAN>";

print $query->textfield(-name=>'category',
			-size=>30,
			-wrap=>'soft',
			-maxlength=>50);

print "<BR><BR><SPAN CLASS=\"copy\">Please enter a category description.<BR><BR></SPAN>";


print $query->textarea(-name=>'description',
                       -rows=>3,
                       -columns=>50,
                       -wrap=>'hard',
                       -onKeyDown=>'wordCounter(this.form.description,this.form.remLen,100)',
                       -onKeyUp=>'wordCounter(this.form.description,this.form.remLen,100)');
print "<BR><SPAN CLASS=\"copy\">Words remaining:&nbsp;</span>";
print $query->textfield(-name=>'remLen', -size=>3, -default=>'100');
print "<BR><SPAN CLASS=\"copy\">Please limit your description to 100 words.</span>\n";
print "<BR><BR>";

print $query->submit(-name=>'submit',
			-value=>'Submit');
print $query->endform;

print "\n</CENTER>\n";

print $query->end_html;
