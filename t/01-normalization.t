#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version;

plan tests => 14;

BEGIN {
  my $v = Java::Maven::Artifact::Version->new('1.0');

  #test 1 : 1.0 normalized to (1)
  is($v->to_string(), '(1)');
  
  #test 2 : 1.0.1 normalized to (1,0,1)
  $v = Java::Maven::Artifact::Version->new('1.0.1');
  is($v->to_string(), '(1,0,1)');

  #test 3 : 1.0-1 normalized to (1,(1))
  $v = Java::Maven::Artifact::Version->new('1.0-1');
  is($v->to_string(), '(1,(1))');

  #test 4 : 1.0-1-alpha-1 normalized to (1,(1,alpha,1))
  $v = Java::Maven::Artifact::Version->new('1.0-1-alpha-1');
  is($v->to_string(), '(1,(1,alpha,1))');

  #test 5 : 222-ga.0.1-final.1-1-rc.final normalized to (222,,0,1,,1,(1,rc))
  $v = Java::Maven::Artifact::Version->new('222-ga.0.1-final.1-1-rc.final');
  is($v->to_string(), '(222,,0,1,,1,(1,rc))');

  #test 6 : 1.0-final-1.0.1-1-4-SNAPSHOT normalized to (1,,1,0,1,(1,(4,snapshot)))
  $v = Java::Maven::Artifact::Version->new('1.0-final-1.0.1-1-4-SNAPSHOT');
  is($v->to_string(), '(1,,1,0,1,(1,(4,snapshot)))');

  #test 7 : 1.1-1.1-1.1-1.1 normalized to (1,1,(1,1,(1,1,(1,1))))
  $v = Java::Maven::Artifact::Version->new('1.1-1.1-1.1-1.1');
  is($v->to_string(), '(1,1,(1,1,(1,1,(1,1))))');

  #test 8 : 1....1 normalized to (1,0,0,0,1)
  $v = Java::Maven::Artifact::Version->new('1....1');
  is($v->to_string(), '(1,0,0,0,1)');
  
  #test 9 : special alias 'a\d' normalization test
  $v = Java::Maven::Artifact::Version->new('a1');
  is($v->to_string(), '(alpha,1)');
  
  #test 10 : special alias 'a\d' normalization test
  $v = Java::Maven::Artifact::Version->new('1-a1');
  is($v->to_string(), '(1,alpha,1)');
  
  #test 11 : special alias 'b\d' normalization test
  $v = Java::Maven::Artifact::Version->new('b1');
  is($v->to_string(), '(beta,1)');
  
  #test 12 : special alias 'b\d' normalization test
  $v = Java::Maven::Artifact::Version->new('1-b1');
  is($v->to_string(), '(1,beta,1)');

  #test 13 : special alias 'm\d' normalization test
  $v = Java::Maven::Artifact::Version->new('m1');
  is($v->to_string(), '(milestone,1)');
  
  #test 14 : special alias 'm\d' normalization test
  $v = Java::Maven::Artifact::Version->new('1-m1');
  is($v->to_string(), '(1,milestone,1)');
}

diag( "Testing normalization Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
