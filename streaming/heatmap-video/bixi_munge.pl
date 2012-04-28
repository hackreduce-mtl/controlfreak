#!/usr/bin/env perl

use strict;
use XML::Bare;
use 5.010;
use Text::CSV;

my $file_name = $ARGV[0];

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();
my $station_xml = `cat $file_name`;
my $ob = new XML::Bare( text => $station_xml) or die "Error creating XML::Bare object for file $file_name";
my $root = $ob->parse() or die "Error parsing file $file_name";;
my $parsed_stations = $root->{stations}->{station}; 
my $timestamp = $root->{stations}->{lastUpdate}->{value};
$file_name=~s/..ml//g;
$timestamp = `basename $file_name` unless $timestamp;
chomp $timestamp;

open my $fh , '>',  "/tmp/$timestamp.csv";

#my @keys = ('id', 'name', 'terminalName', 'lat', 'long', 'installed', 'locked', 'installDate', 'removalDate', 'temporary', 'nbBikes', 'nbEmptyDocks', 'latestUpdateTime');
my @keys = ('lat', 'long', 'nbBikes');
foreach my $station (@{$parsed_stations}) {
        my @values;
        push(@values, $timestamp);
        foreach my $key (@keys) {
      	  my $val = $station->{$key}->{value};
      	  push(@values,$val);
        }
       $csv->combine(@values);
       print $fh $csv->string(), "\n";
}
print "/tmp/$timestamp.csv", "\n";
