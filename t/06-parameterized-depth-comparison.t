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
  is($v->compare_to('1.1', 2), 0);
  
  # test suited depth comparison
  is($v->compare_to('1.1', 3), 1);

  # test too long depth comparison
  is($v->compare_to('1.1', 4), 1);

  # test flat versions comparison with stringitem, short depth
  is($v->compare_to('1-rc', 1), 0);
  
  # test flat versions comparison with stringitem, long depth
  is($v->compare_to('1-rc', 2), 1);
  
  # test deep versions comparison, short depth
  $v = Java::Maven::Artifact::Version->new(version => '1-1.1');
  is($v->compare_to('1-1', 2), 0);
  
  # test deep versions comparison, long depth
  is($v->compare_to('1-1.2', 3), -1);
  
  # test deep versions comparison, too long depth
  is($v->compare_to('1-1.2', 8), -1);

  # test deep versions comparison, listitem with stringitem
  is($v->compare_to('1-sp', 3), 1);
  
  # test deep versions comparison, listitem with nullitem 
  is($v->compare_to('1-ga', 3), 1);
  
  # test very deep versions comparison
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0-1-ga-O-1.2');
  is($v->compare_to('1-1.0-1-ga-O-1.3', 4), 0);
  #                  ^ ^   ^      ^

  # test parameterized max_depth while constructing version
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0', max_depth => 2);
  is($v->compare_to('1-1.1'), 0);

  # test parameterized negative max_depth 
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0', max_depth => -1);
  is($v->compare_to('1-1.1'), 0);

}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION parameterized depth comparison features" );
