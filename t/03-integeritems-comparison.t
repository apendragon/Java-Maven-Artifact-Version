#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 9;

BEGIN {
  my $v = Java::Maven::Artifact::Version->new(version => '1');

  #test 1 : integeritem with integeritem - inferiority
  is($v->compare_to(version => 2), -1);

  #test 2 : integeritem with integeritem - superiority
  $v = Java::Maven::Artifact::Version->new(version => '2');
  is($v->compare_to(version => 1), 1);
  
  #test 3 : integeritem with integeritem - equality
  is($v->compare_to(version => 2), 0);

  #test 4 : integeritem with stringitem - superiority
  $v = Java::Maven::Artifact::Version->new(version => '1.1');
  is($v->compare_to(version => '1-m1'), 1);

  #test 5 : integeritem with listitem - superiority
  is($v->compare_to(version => '1-1'), 1);

  #test 6 : integeritem with nullitem - case of superiority
  $v = Java::Maven::Artifact::Version->new(version => '1.1.1');
  is($v->compare_to(version => '1.ga.1'), 1);
  
  #test 7 : integeritem with nullitem - case of equality
  $v = Java::Maven::Artifact::Version->new(version => '1.0.1');
  is($v->compare_to(version => '1..1'), 0); #_replace_alias do the job
  
  #test 8 : 0 integeritem lower than 'sp' qualifier
  $v = Java::Maven::Artifact::Version->new(version => '0');
  is($v->compare_to(version => 'sp'), -1); 
  
  #test 9 : 0 integeritem greater than 'SNAPSHOT' qualifier
  $v = Java::Maven::Artifact::Version->new(version => '1-1.0.sp');
  is($v->compare_to(version => '1-1-SNAPSHOT'), 1); 
}

diag( "Testing integer items comparison Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
