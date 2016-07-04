#!/usr/bin/perl

#  generate.sh
#  Restless
#
#  Created by Nate Petersen on 8/30/15.
#  Copyright (c) 2015 Digital Rickshaw. All rights reserved.

# TODO: Warning, atrocious Perl code ahead! Should be re-written by someone more adept than me.

use strict;
use warnings;
use JSON::PP;

my $infilename = shift;
my $outdir = shift;

print "Parsing file: ${infilename}\n";

open(FILEIN, $infilename) or die "Can't open $infilename: $!";
my $string = join("", <FILEIN>); 
close FILEIN;

# Find the protocol declaration
if ($string =~ m/\@protocol ([a-zA-Z0-9_]*) <LAWebService>/ ) {
	print "Protocol: ${1}\n";

	my $outfilename = "${outdir}/${1}.laproto";
	print "Output file name: ${outfilename}\n";

	my %annoMap = ();

	# Find each annotated method
	while($string =~ m/(@[a-zA-Z]*\([\S\s]*?;)\n/g ) {
		print "===========================================\n";
		print "Working on method blob:\n${1}\n\n";
		
		my @lines = split /^/, $1;
		my $numLines = @lines;
		my %annotations = ();
		my $i = 0;

		# Find each annotation
		for (; $i < $numLines - 1; $i++) {
			my $line = $lines[$i];

			print "Working on ${line}\n";

			if ($line =~ m/@([a-zA-Z]*)\(([{"].*["}])\)/g) {
				my $annoName = $1;
				my $annoValue = $2;
				print "Got annotation, ${annoName} : ${annoValue}\n";
				
				if ($annoValue =~ /^["]/) {
					$annoValue = substr $annoValue, 1, -1;
					print "final annotation value: ${annoValue}\n";
					$annotations{$annoName} = $annoValue;
				} else {
					my %object = %{ decode_json $annoValue };
					print "final annotation value: @{[%object]}\n";
					$annotations{$annoName} = \%object;
				}
			} elsif ($line =~ m/@([a-zA-Z]*)/g) {
				my $annoName = $1;
				print "Got annotation, ${annoName}\n";
				$annotations{$annoName} = JSON::PP::true;
			} else {
				# assuming the rest is the method sig itself
				last;
			}
		}

		print "Collected annotations:@{[%annotations]}\n";
	
		chomp(@lines);

		# Get the method signature
		my $methodString = join(" ", @lines[$i .. $#lines]);

		print "Working on method string: ${methodString}\n";

		my $methodSig = "";

		while ($methodString =~ m/.*?\(.*?\).*?([a-zA-Z0-9_]+)[\s]*:/g) {
			$methodSig = $methodSig . $1 . ":";
		}

		if (length($methodSig) == 0) {
			if ($methodString =~ m/.*\(.*\)([a-zA-Z0-9_]+)[\s]*;/g) {
				$methodSig = $1;
			}
		}

		print "Found method sig: ${methodSig}\n";

		my %methodDesc = ();

		$methodDesc{"annotations"} = \%annotations;

		print "Working on param names\n";

		# Capture the parameter names
		my @params = ();
		while ($methodString =~ m/:[\s]*\(([^)]*)\)[\s]*([a-zA-Z0-9_]+)/g) {
			my $filedName1 = $1;
			my $filedName2 = $2;
			if ($filedName1 =~ m/Part\([\s]*"([a-zA-Z0-9_]*)"/g) {
				print "find part : $1\n";
				push @params, $1;
			}
			elsif($filedName1 =~ m/Header\([\s]*"([a-zA-Z0-9_]*)"/g){
				print "find Header : -H$1\n";
				push @params, $1;
			}
			else{
				print "find param : $2\n";
				push @params, $2;
			}

		}

		$methodDesc{"parameterNames"} = \@params;

		# Capture the desired NSURLSessionTask sub-type (from the return value)
		print "working on task type\n";
		
		if ($methodString =~ m/-[\s]*\([\s]*LANSignal\(([^)]*)\)/g) {
			$methodDesc{"reformaterName"} = $1;
		}
	

		$annoMap{$methodSig} = \%methodDesc;
	}

	open(FILEOUT, ">$outfilename") or die "Can't write to $outfilename: $!";

	print "final map:@{[%annoMap]}\n";
	my $jsonstring = encode_json \%annoMap;
	print FILEOUT $jsonstring;

	close FILEOUT;
}