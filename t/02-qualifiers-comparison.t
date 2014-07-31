#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 12;

BEGIN {
  my $v = Java::Maven::Artifact::Version->new(version => 'alpha');

  #test 1 : alpha < beta
  is($v->compare_to(version => 'beta'), -1);
  
  #test 2 : beta < milestone
  $v = Java::Maven::Artifact::Version->new(version => 'beta');
  is($v->compare_to(version => 'milestone'), -1);
  
  #test 3 : milestone < rc
  $v = Java::Maven::Artifact::Version->new(version => 'milestone');
  is($v->compare_to(version => 'rc'), -1);
  
  #test 4 : rc < ''
  $v = Java::Maven::Artifact::Version->new(version => 'rc');
  is($v->compare_to(version => 'ga'), -1);
  
  #test 5 : '' < sp
  $v = Java::Maven::Artifact::Version->new();
  is($v->compare_to(version => 'sp'), -1);
  
  #test 6 : sp < xxx
  $v = Java::Maven::Artifact::Version->new(version => 'sp');
  is($v->compare_to(version => 'xxx'), -1);

  #test 7 : sp > '' (inversion of test just to check it can return something else of -1)
  $v = Java::Maven::Artifact::Version->new(version => 'sp');
  is($v->compare_to(version => 'ga'), 1);

  #test 8 : xx < xxx
  $v = Java::Maven::Artifact::Version->new(version => 'xx');
  is($v->compare_to(version => 'xxx'), -1);

  #test 9 : a < b
  $v = Java::Maven::Artifact::Version->new(version => 'a');
  is($v->compare_to(version => 'b'), -1);
  
  #test 10 : a < aa
  $v = Java::Maven::Artifact::Version->new(version => 'a');
  is($v->compare_to(version => 'aa'), -1);
  
  #test 11 : a == a (equality test not done until this one)
  $v = Java::Maven::Artifact::Version->new(version => 'a');
  is($v->compare_to(version => 'a'), 0);
  
  #test 12 : milestone == milestone (equality test not done until this one on known qualifiers)
  $v = Java::Maven::Artifact::Version->new(version => 'milestone');
  is($v->compare_to(version => 'milestone'), 0);
}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION qualifiers comparison feature" );
