#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 13;

BEGIN {
  
  # test 1 flat versions comparison
  my $v = Java::Maven::Artifact::Version->new(version => '1.1.1');
  is($v->compare_to(version => '1.1', max_depth => 2), 0);
  
  # test 2 suited depth comparison
  is($v->compare_to(version => '1.1', max_depth => 3), 1);

  # test 3 too long depth comparison
  is($v->compare_to(version => '1.1', max_depth => 4), 1);

  # test 4 flat versions comparison with stringitem, short depth
  is($v->compare_to(version => '1-rc', max_depth => 1), 0);
  
  # test 5 flat versions comparison with stringitem, long depth
  is($v->compare_to(version => '1-rc', max_depth => 2), 1);
  
  # test 6 deep versions comparison, short depth
  $v = Java::Maven::Artifact::Version->new(version => '1-1.1');
  is($v->compare_to(version => '1-1', max_depth => 2), 0);
  
  # test 7 deep versions comparison, long depth
  is($v->compare_to(version => '1-1.2', max_depth => 3), -1);
  
  # test 8 deep versions comparison, too long depth
  is($v->compare_to(version => '1-1.2', max_depth => 8), -1);

  # test 9 deep versions comparison, listitem with stringitem
  is($v->compare_to(version => '1-sp', max_depth => 3), 1);
  
  # test 10 deep versions comparison, listitem with nullitem 
  is($v->compare_to(version => '1-ga', max_depth => 3), 1);
  
  # test 11 very deep versions comparison
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0-1-ga-O-1.2');
  is($v->compare_to(version => '1-1.0-1-ga-O-1.3', max_depth => 4), 0);
  #                             ^ ^   ^      ^

  # test 12 parameterized max_depth while constructing version
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0', max_depth => 2);
  is($v->compare_to(version => '1-1.1'), 0);

  # test 13 parameterized negative max_depth 
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0', max_depth => -1);
  is($v->compare_to(version => '1-1.1'), 0);

}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION parameterized depth comparison features" );
