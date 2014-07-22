#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 12;

BEGIN {
  my $v = Java::Maven::Artifact::Version->new('alpha');

  #test 1 : alpha < beta
  is($v->compare_to('beta'), -1);
  
  #test 2 : beta < milestone
  $v = Java::Maven::Artifact::Version->new('beta');
  is($v->compare_to('milestone'), -1);
  
  #test 3 : milestone < rc
  $v = Java::Maven::Artifact::Version->new('milestone');
  is($v->compare_to('rc'), -1);
  
  #test 4 : rc < ''
  $v = Java::Maven::Artifact::Version->new('rc');
  is($v->compare_to('ga'), -1);
  
  #test 5 : '' < sp
  $v = Java::Maven::Artifact::Version->new();
  is($v->compare_to('sp'), -1);
  
  #test 6 : sp < xxx
  $v = Java::Maven::Artifact::Version->new('sp');
  is($v->compare_to('xxx'), -1);

  #test 7 : sp > '' (inversion of test just to check it can return something else of -1)
  $v = Java::Maven::Artifact::Version->new('sp');
  is($v->compare_to('ga'), 1);

  #test 8 : xx < xxx
  $v = Java::Maven::Artifact::Version->new('xx');
  is($v->compare_to('xxx'), -1);

  #test 9 : a < b
  $v = Java::Maven::Artifact::Version->new('a');
  is($v->compare_to('b'), -1);
  
  #test 10 : a < aa
  $v = Java::Maven::Artifact::Version->new('a');
  is($v->compare_to('aa'), -1);
  
  #test 11 : a == a (equality test not done until this one)
  $v = Java::Maven::Artifact::Version->new('a');
  is($v->compare_to('a'), 0);
  
  #test 12 : milestone == milestone (equality test not done until this one on known qualifiers)
  $v = Java::Maven::Artifact::Version->new('milestone');
  is($v->compare_to('milestone'), 0);
}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION qualifiers comparison feature" );
