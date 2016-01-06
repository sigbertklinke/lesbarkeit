#!/usr/bin/perl

# Copyright 2003-2016 Sigbert Klinke (sigbert.klinke@web.de)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Encode;
use HTML::Template;
use HTML::Entities;
use File::Slurp;

sub ReadFile {
    my ($fname) = @_;
    my ($fcont);
    open (FILE, "<:encoding(UTF-8)", $fname) || die ("Can not open file: $fname");
    undef $/;
    $fcont = <FILE>;
    close (FILE);
    return $fcont;
}

sub ChangeSpecialCharacter {
    chomp ($line);
    $line =~ s/\xE4/ae/g;
    $line =~ s/\xF6/oe/g;
    $line =~ s/\xFC/ue/g;
    $line =~ s/\xDF/ss/g;
    $line =~ s/\xC4/Ae/g;
    $line =~ s/\xD6/Oe/g;
    $line =~ s/\xDC/Ue/g;
}

sub SplitSentences {
    @chars = split (//, $line);
    @sentences = ();
    $sentence = '';
    $sentenceend = 0;
    $bracket = 0;
    $delim = '.?!';
    foreach $char (@chars) {
	if (($char eq ' ') && ($sentenceend == 1)) {
	    push (@sentences, $sentence);
	    $sentence = '';
	    $sentenceend = 0;
	} else {
	    if ($char eq '(') { $bracket++; }
	    if ($char eq ')') { $bracket--; }
	    if ($char eq "\x84") { $citation++; }
	    if ($char eq "\x93") { $citation--; }
	    $sentence .= $char;
	    if (($bracket == 0) & ($citation == 0)) {
		$sentenceend = ((($char eq '.') || ($char eq '?') || ($char eq '!')) && ($sentence !~ /[0-9A-Z]+\.$/));
	    }
	}
    }
    push (@sentences, $sentence);
    return (@sentences);
}

sub AnalyzeSentence {
    my @word1 = ();
    my @word2 = ();
    $sent = {};
    @wordlist = split (/ +/, $sentence);
    $swd = @wordlist;
    $slw = 0;
    $sos = 0;
    $ssl = 0;
    $ssy = 0;
    foreach $word (@wordlist) {
	my %tmp = ('word' => $word);
	push (@word1, \%tmp);

	$double = 0;
	pos($word) = 0;
	$single = 0;
	while ($word =~ /ei|au|ie|ae|oe|ue|Ei|Au|Ae|Oe|Ue/g) { $double++; }
	pos($word) = 0;
	while ($word =~ /a|e|i|o|u|A|E|I|O|U/g) { $single++; } 
	$sylabels = $single-$double;

	my %tmp = ('wsl' => $sylabels);
	push (@word2, \%tmp);

	$ssl += $sylabels;
	@cl = split (//, $word);
	if (@cl>5) { $slw++; }
	if ($sylabels==1) { $sos++; }
	if ($sylabels>2) { $ssy++; }
    }
    $sent->{WORD1} = \@word1;
    $sent->{WORD2} = \@word2;
    $sent->{'swd'} = $swd;
    $sent->{'slw'} = $slw;
    $sent->{'sos'} = $sos;
    $sent->{'ssl'} = $ssl;
    $sent->{'ssy'} = $ssy;
    if ($swd>0) {
	$sent->{'amdahl'} = sprintf ("%.0f", $swd + 58.5 * ($ssl/$swd));
	$sent->{'smog'}   = sprintf ("%.1f", sqrt (100*$ssy/$swd) - 2);
	$sent->{'wstf'}   = sprintf ("%.1f", 0.1935* ($ssy/$swd) + 0.1672* $swd + 0.1297 * $slw/$swd - 0.0327 * $sos);
    } else {
	$sent->{'amdahl'} = "-";
	$sent->{'smog'}   = "-";
	$sent->{'wstf'}   = "-";
    }
    return ($sent);
}

sub AnalyzeText {
    my ($txt) = @_;
    my (@paragraphs); 
    my ($paragraph, $template);
    @paragraphs = split (/\n[ \t\r\f]*\n/, $txt);
    foreach $paragraph (@paragraphs) {
	print "$paragraph\n";
    }

    my $np = @paragraphs;
    print "$np paragraphs\n";
    return (@paragraphs);
}

$fname = $ARGV[0];

@paragraphs = AnalyzeText (ReadFile ("$fname.txt"));

$template = HTML::Template->new(filename => 'base.htm', option => 'value', global_vars => 1, die_on_bad_params => 0);

$template->param('fname' => $fname);

$paragraphno = 1;
$tss = 0;
$twd = 0;
$tlw = 0;
$tos = 0;
$tsl = 0;
$tsy = 0;
@loop = ();
foreach $line (@paragraphs) {
    $loopitem = {};
    $loopitem->{'linktxt'} = substr($line, 0, 35);
    $loopitem->{'paragraphno'} = $paragraphno++;

    ChangeSpecialCharacter ();
    @sentencelist = SplitSentences();

    $ass = 0;
    $awd = 0;
    $alw = 0;
    $aos = 0;
    $asl = 0;
    $asy = 0;
    my @sloop = ();
    $j=0;
    foreach $sentence (@sentencelist) {
	$sent = AnalyzeSentence();
	push (@sloop, $sent);
	if ($swd > 0) { $ass++; }
	$awd += $swd;
	$alw += $slw;
	$aos += $sos;
	$asl += $ssl;
	$asy += $ssy;
    }       
    $loopitem->{'SENTENCE'} =  encode_entities(\@sloop);
    $loopitem->{'ass'}    = $ass;
    $loopitem->{'awd'}    = $awd;
    $loopitem->{'alw'}    = $alw;
    $loopitem->{'aos'}    = $aos;
    $loopitem->{'asl'}    = $asl;
    $loopitem->{'asy'}    = $asy;
    if (($ass>0) && ($awd>0)) {
	$loopitem->{'amdahl'} = sprintf ("%.0f", ($awd/$ass) + 58.5 * ($asl/$awd));
	$loopitem->{'smog'}   = sprintf ("%.1f", sqrt (100*$asy/$awd) - 2);
	$loopitem->{'wstf'}   = sprintf ("%.1f", 0.1935* ($asy/$awd) + 0.1672* $awd/$ass + 0.1297 * $alw/$awd - 0.0327 * $aos/$ass);
    } else {
	$loopitem->{'amdahl'} = '.';
        $loopitem->{'smog'}   = '.';
        $loopitem->{'wstf'}   = '.';
    }
    push (@loop, $loopitem);

    $tss += $ass;
    $twd += $awd;
    $tlw += $alw;
    $tos += $aos;
    $tsl += $asl;
    $tsy += $asy;
}
$template->param(PARAGRAPH => \@loop);

if (($tss>0) && ($twd>0)) {
    $amdahl = sprintf ("%.0f", ($twd/$tss) + 58.5 * ($tsl/$twd));
    $smog   = sprintf ("%.1f", sqrt (100*$tsy/$twd) - 2);
    $wstf   = sprintf ("%.1f", 0.1935* ($tsy/$twd) + 0.1672* $twd/$tss + 0.1297 * $tlw/$twd - 0.0327 * $tos/$tss);
} else {
    $amdahl = -1;
    $smog   = -1;
    $wstf   = -1;
}
$template->param('tss' => $tss);
$template->param('twd' => $twd);
$template->param('tlw' => $tlw);
$template->param('tos' => $tos);
$template->param('tsl' => $tsl);
$template->param('tsy' => $tsy);
$template->param('amdahl' => $amdahl);
$template->param('smog' => $smog);
$template->param('wstf' => $wstf);

open (HTM, ">$fname.htm") || die ("Can not open $fname.htm");
print HTM $template->output();
close (HTM);
