#!/usr/bin/perl

#  generate.sh
#  LAFramework
#
#  Created by LakeR on 7/28/16.
#  Copyright (c) 2016 LakeR inc. All rights reserved.


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
if ($string =~ m/\@interface ([a-zA-Z0-9_]*)/ ) {
	print "Class: ${1}\n";

	my $outfilename = "${outdir}/${1}.lajson";
	print "Output file name: ${outfilename}\n";

	my %annoMap = ();

	# Find each annotated method
	while($string =~ m/([@]Json[a-zA-Z]*[\S\s]*?[;|\@interface][\s\S*])\n/g ) {
		print "===========================================\n";
		print "Working on property blob:\n${1}\n\n";
		
		my @lines = split /^/, $1;
		my $numLines = @lines;
		my %annotations = ();
		my $i = 0;

		# Find each annotation
		for (; $i < $numLines - 1; $i++) {
			my $line = $lines[$i];

			print "Working on ${line}\n";

			if ($line =~ m/@(Json[a-zA-Z]*)\(([{"].*["}])\)/g) {
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
			} elsif ($line =~ m/@(Json[a-zA-Z]*)/g) {
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
		my $propertyString = join(" ", @lines[$i .. $#lines]);

		print "Working on property string: ${propertyString}\n";

		my $propertyName = "";
    
        if($propertyString =~ m/\@interface\s+(\w+)[\s|\S]*{/g){
            print "interface name ${1}\n";
            $propertyName = "__Class__" . $1 ;
        }
        $propertyString = reverse $propertyString;
            
        if($propertyString =~ m/;\s*([a-zA-Z0-9_]+)/g){
            $propertyName = reverse $1;
        }
        
		if (length($propertyName) == 0) {
			if ($propertyString =~ m/.*\(.*\)([a-zA-Z0-9_]+)[\s]*;/g) {
				$propertyName = $1;
			}
		}
            
            

		print "Found method sig: ${propertyName}\n";
		$annoMap{$propertyName} = \%annotations;
	}

	open(FILEOUT, ">$outfilename") or die "Can't write to $outfilename: $!";

	print "final map:@{[%annoMap]}\n";
	my $jsonstring = encode_json \%annoMap;
	print FILEOUT $jsonstring;

	close FILEOUT;
}