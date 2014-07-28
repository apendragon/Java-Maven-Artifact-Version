#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 3;

BEGIN {
  my $v = Java::Maven::Artifact::Version->new(version => '1-xxxxx');

  #test 1 : integer item is greater
  is($v->compare_to('1.1'), -1);

  #test 2 : listitem is greater
  is($v->compare_to('1-0.1'), -1);

  #test 3 : nullitem is equal when qualifier is '' or alias
  $v = Java::Maven::Artifact::Version->new(version => '1-ga');
  is($v->compare_to('1'), 0); #normalization do the job
  
  #stringitem with stringitem comparisons have already been tested in t/02-qualifiers-comparison.t
}

diag( "Testing string items comparison Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
