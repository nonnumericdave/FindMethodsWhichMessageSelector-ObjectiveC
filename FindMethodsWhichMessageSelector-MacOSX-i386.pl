#!/usr/bin/perl

use strict;
use warnings;

if ( scalar(@ARGV) != 2 )
{
	print "Usage: $0 <i386 Objective-C Library> <Objective-C Selector>\n";
	exit(255);
}

my $szLib = $ARGV[0];
my $szSelector = $ARGV[1];

my %hClassRefs = ();

print "\nSelector \"$szSelector\" implementation found at:\n";

open(OTOOL, "xcrun otool -arch i386 -v -s __OBJC __message_refs $szLib|");
while (<OTOOL>)
{
	chomp;

	if ( m/^([\da-fA-F]{8})\s+__TEXT:__cstring:($szSelector)$/ )
	{
		$hClassRefs{hex($1)} = $2;
		print "  $_";
	}
}

close(OTOOL);

print "\n\nSelector \"$szSelector\" appears to be called from the following methods:\n";

my $szLastFunctionName = "";
my @aszLastFunctionBody = ();

open(OTOOL, "xcrun otool -arch i386 -v -V -t $szLib|");
while (<OTOOL>)
{
	chomp;

	if ( m/^([\da-fA-F]{8})\s+/ )
	{
		push(@aszLastFunctionBody, $_);
	}
	else
	{
		if ( scalar(@aszLastFunctionBody) > 0 )
		{
			if ( CheckFunctionForSymbolReference(@aszLastFunctionBody) )
			{
				print "  $szLastFunctionName\n";
			}
		}

		$szLastFunctionName = $_;
		@aszLastFunctionBody = ();	
	}
}

if ( scalar(@aszLastFunctionBody) > 0 )
{
	if ( CheckFunctionForSymbolReference(@aszLastFunctionBody) )
	{
		print "$szLastFunctionName\n";
	}
}

close(OTOOL);

print "\n";

sub CheckFunctionForSymbolReference
{
	my @aszFunctionBody = @_;

	my $i = 0;

	my $szPICReg = "";
	my $iPICRegVal = 0;

	for (; $i < scalar(@aszFunctionBody); $i++)
	{
		my $szInst = $aszFunctionBody[$i];

		if ( $szInst =~ m/^([\da-fA-F]{8})\s+calll\s+0x([\da-fA-F]{1,8})/ )
		{
			my $iCallAdd = hex($2);
		
			last if ( ($i + 1) >= scalar(@aszFunctionBody) );

			my $szNextInst = $aszFunctionBody[$i + 1];

			if ( $szNextInst =~ m/^([\da-fA-F]{8})\s+popl\s+(%[^\s]*)/ )
			{
				my $iAdd = hex($1); 
	
				if ( $iCallAdd == $iAdd )
				{
					$i++;

					$szPICReg = $2;

					$iPICRegVal = $iAdd;

					last;
				}
			}
		}
	}

	for (; $i < scalar(@aszFunctionBody); $i++)
	{
		my $szInst = $aszFunctionBody[$i];

		if ( $szInst =~ m/^([\da-fA-F]{8})\s+movl\s+0x([\da-fA-F]{1,8})\($szPICReg\),/ )
		{
			my $iAddOffset = hex($2);

			my $iAbsAdd = $iAddOffset + $iPICRegVal;

			if ( exists($hClassRefs{$iAbsAdd}) )
			{
				return 1;
			}
		}	
	}

	return 0;
}
