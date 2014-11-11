#!perl -T
use 5.8.8;
use strict;
use warnings FATAL => 'all';
use Test::More;
use CPAN::Meta::Validator;
use Parse::CPAN::Meta;

plan tests => 1;
my $struct= Parse::CPAN::Meta->load_file('MYMETA.json');
my $cmv = CPAN::Meta::Validator->new( $struct );
unless ( $cmv->is_valid ) {
  my $msg = "Invalid META structure.  Errors found:\n";
  $msg .= join( "\n", $cmv->errors );
  warn $msg;
}
is($cmv->is_valid, 1);
