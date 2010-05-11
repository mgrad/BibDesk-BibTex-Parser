#!/usr/bin/perl -w

# -------------- subs ----------------- #
sub usage {
  print STDERR <<EOM;
This tool converts the *.bib file generated from BibDesk.
It changes the Bdsk-File entry which points to the pdf file.

  Usage:
  1. Export from the BibDesk the BibTex & EndNote databases.
  - this will genearte the *.bib and *.xml files accordinally.
  2. $0 *.bib *.xml
EOM
  exit 1;
}

sub wrong_args {
  print STDERR "Wrong arguments\n";
  exit 2;
}

sub file_not_exists {
  print STDERR "File do not exists\n";
  wrong_args;
}

sub dprint {
  print @_ if $::debug;
}

# -------------- main ----------------- #
usage if (scalar(@ARGV) < 2);

my $bibFile = shift || die;
my $xmlFile = shift || die;
local $debug = shift || 0;

wrong_args if (($bibFile !~ /bib$/)  or ($xmlFile !~ /xml$/));
file_not_exists if ( ! -e $bibFile or ! -e $xmlFile);

my $regTitle = qr/\<title\>(.*)\<\/title\>/;
my $regURL   = qr/\<url\>(.*)\<\/url\>/;
my %db;

# read the title and pdf_path from XML file
open(SRC_XML, "$xmlFile");
while (my $line = <SRC_XML> ) {
  if ($line =~ /$regTitle.*$regURL/) {
    $db{$1} = $2;
    dprint "{$1} , {$2}\n"
  }
}
close(SRC_XML);

# parse *.bib file and replace the Bdsk-File with local-uri
open(SRC_BIB, "$bibFile");
my $match = 0;
my $title = "";
while (my $line = <SRC_BIB> ) {
  # new bib record
  $match = 0 if $line =~ /^@/;

  # find title
  if ($line =~ /Title\s*=\s*{(.*)}/) {
    $title = $1;
    $match = 1 if exists $db{$title};
  }

  # found multiple-line entry
  $found = 1 if ($match && $line =~ /^\s*Bdsk-File/);

  # processing entry
  unless ($found) {
      print $line;
  } else {
    if ($line =~ /^\s*$/ or $match == 0 or eof(SRC_BIB) ) {
      print "\tlocal-url = {$db{$title}}\n}\n\n";
      $found = 0;
    }
  }
}
close(SRC_BIB);
