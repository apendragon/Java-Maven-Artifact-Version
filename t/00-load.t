#!perl -T
use 5.8.8;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Java::Maven::Artifact::Version' ) || print "Bail out!\n";
}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION, Perl $], $^X" );
