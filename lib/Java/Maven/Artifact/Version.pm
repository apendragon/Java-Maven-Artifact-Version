package Java::Maven::Artifact::Version;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Scalar::Util qw/reftype/;
use Hash::Util qw/lock_value/;
use Language::Functional;

=head1 NAME

Java::Maven::Artifact::Version - a perl module for comparing Artifact versions like Maven does.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Note that this documentation is intended as a reference to the module.

    use Java::Maven::Artifact::Version;

    my $foo_version = Java::Maven::Artifact::Version->new(version => '1.0');
    my $bar_version = Java::Maven::Artifact::Version->new(version => '1-0-alpha');
    my $x = $bar_version->compare_to($bar_version); # $x = 0
    ...

    my $com_version = Java::Maven::Artifact::Version->new(version => '1-alpha');
    my $y = $com_version->compare_to('1-beta'); # $y = -1 
    ...

    my $baz_version = Java::Maven::Artifact::Version->new(version => '1-1.2-alpha');
    my $z = $baz_version->to_string(); # $z = '(1,(1,2,alpha))' 
    ...

=head1 DESCRIPTION

L<Apache Maven|http://maven.apache.org/>  has a peculiar way to compare Artifact versions.
The aim of this module is to exactly reproduce this way in hope that it could be usefull to write utils like SCM hooks to quickly ensure an Artifact version respect a grow order without to have to install Java and Maven on the system in charge of this checking.

The official Apache document that describes it is here L<http://docs.codehaus.org/display/MAVEN/Versioning>.
But don't blindly believe everything. Take the red pill, and I show you how deep the rabbit-hole goes.
Because there is a gap between the truth coded in C<org.apache.maven.artifact.versioning.ComparableVersion.java> that can be found L<here|https://github.com/apache/maven/blob/master/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java> and this document.





TODO say normalize is done when a dash '-' is preceed by a digit, before alias replacement

=head2 NULL_ITEM

=cut

=head2 STRING_ITEM

=cut

=head2 SNAPSHOT

=cut

=head2 SP

=cut


=head2 INTEGER_ITEM

=cut

=head2 LIST_ITEM

=cut

=head2 ALPHA

=cut

=head2 BETA
  
=cut

=head2 MILESTONE

=cut

=head2 RC

=cut

use constant {
  ALPHA        => 'alpha',
  BETA         => 'beta', 
  DEBUG        => 1,
  INTEGER_ITEM => 'integeritem',
  LIST_ITEM    => 'listitem',
  MILESTONE    => 'milestone',
  NULL_ITEM    => 'nullitem',
  RC           => 'rc',
  SNAPSHOT     => 'snapshot',
  SP           => 'sp',
  STRING_ITEM  => 'stringitem',
};

=head1 SUBROUTINES/METHODS

=cut

sub _identify_scalar_item_type {
  my ($scalar) = @_;
  $scalar =~ m/^\d+$/ ? INTEGER_ITEM : STRING_ITEM;
}

sub _getref {
  my ($var) = @_;
  (ref($var) || not defined($var)) ? $var : \$var; # var may already be a ref
}

sub _is_nullitem {
  my ($item) = @_;
  (not defined($item)) ? 1 : 'undef' eq reftype(_getref($item));
}

sub _reftype {
  my ($item) = @_;
  _is_nullitem($item) ? 'undef' : reftype(_getref($item));
}

sub _identify_item_type {
  my ($item) = @_;
  my $types = {
    'undef'   => sub { NULL_ITEM }, 
    'SCALAR'  => sub { _identify_scalar_item_type($item) }, 
    'ARRAY'   => sub { LIST_ITEM },
    _DEFAULT_ => sub { die "unable to identify item type of item $item ." }
  };
  my $t = _reftype($item);  
  print("_identify_item_type($t)\n") if (DEBUG);
  exists $types->{$t} ? $types->{$t}->() : $types->{_DEFAULT_}->();
}

sub _compare_integeritem_to {
  my ($integeritem, $item) = @_;
  my $dispatch = {
    &NULL_ITEM    => sub {
      print("comparing $integeritem to nullitem\n") if (DEBUG); 
      $integeritem =~ m/^0+$/ ? 0 : 1;
    },
    &LIST_ITEM    => sub {
      print("comparing $integeritem to listitem\n") if (DEBUG); 
      1;
    },
    &INTEGER_ITEM => sub {
      print("comparing $integeritem to $item\n") if (DEBUG); 
      $integeritem <=> $item;
    },
    &STRING_ITEM  => sub {
      print("comparing $integeritem to stringitem\n") if (DEBUG); 
      1;
    }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_items {
  my ($item1, $item2) = @_;
  my $dispatch = {
    &NULL_ITEM    => sub {
      print("_compare_items(nullitem, ?)\n") if (DEBUG); 
      return 0 unless (defined($item2));
      _compare_items($item2, undef) * -1;
    },
    &LIST_ITEM    => sub {
      print("_compare_items(listitem, ?)\n") if (DEBUG); 
      _compare_listitem_to($item1, $item2);
    },
    &INTEGER_ITEM => sub {
      print("_compare_items(integeritem, ?)\n") if (DEBUG);
      _compare_integeritem_to($item1, $item2);
    },
    &STRING_ITEM  => sub {
      print("_compare_items(stringitem, ?)\n") if (DEBUG);
      _compare_stringitem_to($item1, $item2);
    }
  };
  $dispatch->{_identify_item_type($item1)}->();
}

sub _compare_listitem_to {
  my ($listitem, $item) = @_;
  my $dispatch = {
    &NULL_ITEM    => sub { _compare_listitem_to_nullitem($listitem) },
    &LIST_ITEM    => sub { _compare_listitems($listitem, $item) },
    &INTEGER_ITEM => sub { -1 },
    &STRING_ITEM  => sub { 1 }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_listitem_to_nullitem {
  my ($listitem) = @_;
  if (not @$listitem) {
    warn("comparing listitem with empty listitem should never occur. Check your code boy...");
    0; #empty listitem (theoricaly impossible) equals null item
  } else {
    #only compare first element with null item (yes they did that...)
    _compare_items(@$listitem[0], undef);
  }
}

sub _compare_listitems {
  my ($list1, $list2) = @_;
  my @l = @$list1;
  my @r = @$list2;
  while (@l || @r) {
    my $li = @l ? shift(@l) : undef;
    my $ri = @r ? shift(@r) : undef;
    my $c = defined($li) ? _compare_items($li, $ri) : _compare_items($ri, $li) * -1;
    $c and return $c;
  }
  0;
}

sub _compare_to_mvn_version {
  my ($this, $anotherVersion) = @_;
  die("parameter is not a Java::Maven::Artifact::Version") if not ($anotherVersion->isa('Java::Maven::Artifact::Version')); 
  _compare_listitems($this->{items}, $anotherVersion->{items});
}

sub _compare_stringitem_to {
  my ($stringitem, $item) = @_;
  my $dispatch = {
    &NULL_ITEM    => sub { _compare_stringitem_to_stringitem($stringitem, $item) },
    &LIST_ITEM    => sub { _compare_listitem_to($item, $stringitem) * -1 },
    &INTEGER_ITEM => sub { _compare_integeritem_to($item, $stringitem) * -1 },
    &STRING_ITEM  => sub { _compare_stringitem_to_stringitem($stringitem, $item) }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_stringitem_to_stringitem {
  my ($stringitem1, $stringitem2) = @_;
  _substitute_to_qualifier($stringitem1) cmp _substitute_to_qualifier($stringitem2);
}

sub _normalize {
  my ($listitems) = @_;
  my $norm_sublist;
  if (ref(@$listitems[-1]) eq 'ARRAY') {
    my $sublist = pop(@$listitems);
    $norm_sublist = _normalize($sublist);
  }
  pop(@$listitems) while (@$listitems && @$listitems[-1] =~ m/^(0+|ga|final)?$/ );
  push(@$listitems, $norm_sublist) if (defined($norm_sublist) && @$norm_sublist);
  $listitems;
}

sub _replace_special_aliases {
  my ($string) = @_;
  $string =~ s/((?:^)|(?:\.|\-))a(\d)/$1alpha.$2/g; # a1 = alpha.1
  $string =~ s/((?:^)|(?:\.|\-))b(\d)/$1beta.$2/g; # b11 = beta.11
  $string =~ s/((?:^)|(?:\.|\-))m(\d)/$1milestone.$2/g; # m7 = milestone.7
  $string;
}

sub _replace_alias {
  my ($string) = @_;
  if ($string eq '') {
    return 0;
  } elsif ($string =~ m/^(ga|final)$/) {
    return '';
  } elsif ($string eq 'cr') {
    return 'rc';
  }
  $string;
}

#_normalize must be called each time a digit is followed by a dash
sub _split_to_to_normalize {
  my ($string) = @_;
  $string =~ s#(\d)\-#$1</version>#g; # use '</version>' as seperator because it cannot be a part of an artifact version...
  split('</version>', $string);
}

# _split_to_items must only be called when version has been splitted into listitems
# Then it works only on a single listitem
sub _split_to_items {
  my ($string) = @_;
  my @items = ();
  my @tonormalize = _split_to_to_normalize($string);
  #at this time we must replace aliases with their values 
  foreach my $i (@tonormalize) {
    $i = _replace_special_aliases($i); #must be replaced BEFORE items splitting
    my @xs = split(/\-|\./, $i);
    my @xsp = map({ _replace_alias($_) } @xs); #must be replaced after items splitting
    push(@items, @{_normalize(\@xsp)} );
  }
  @items;
}

sub _split_to_lists {
  my ($string, @items) = @_;
  #listitems are created every encountered dash when there are a digits in front and after it
  if (my ($a, $b) =  ($string =~ m/(.*?\d)\-(\d.*)/)) {
    push(@items, _split_to_items($a), _split_to_lists($b, ()));
  } else { 
    push(@items, _split_to_items($string));
  }
  \@items;
}

sub _identify_qualifier {
  my ($stringitem) = @_;
  return NULL_ITEM unless defined($stringitem);
  return ALPHA     if $stringitem =~ m/^(alpha|a\d+)$/;
  return BETA      if $stringitem =~ m/^(beta|b\d+)$/;
  return MILESTONE if $stringitem =~ m/^(milestone|m\d+)$/;
  return RC        if $stringitem =~ m/^rc$/;
  return SNAPSHOT  if $stringitem =~ m/^snapshot$/;
  return NULL_ITEM if $stringitem =~ m/^$/;
  return SP        if $stringitem =~ m/^sp$/;
  '_DEFAULT_';
}

sub _substitute_to_qualifier {
  my ($stringitem) = @_;
  my $qualifier_cmp_values = {
    &ALPHA     => '0',
    &BETA      => '1',
    &MILESTONE => '2',
    &RC        => '3',
    &SNAPSHOT  => '4',
    &NULL_ITEM => '5',
    &SP        => '6',
    _DEFAULT_  => $stringitem ? "7-$stringitem" : '7-' #yes they really did that in ComparableVersion...
  };
  $qualifier_cmp_values->{_identify_qualifier($stringitem)};
}

sub _to_normalized_string {
  my ($items) = @_;
  my $s = '(';
  foreach my $i (@$items) {
    $s .= ',' if ($s ne '(');
    if (ref($i) eq 'ARRAY') {
      $s .= _to_normalized_string($i);
    } else {
      $s .= "$i";
    }
  }
  $s .= ')';
}

=head2 compare_to 

=cut
sub compare_to {
  my ($this, $anotherVersion) = @_;
  if (ref($anotherVersion) eq 'Java::Maven::Artifact::Version') {
    $this->_compare_to_mvn_version($anotherVersion);
  } else {
    my $other = Java::Maven::Artifact::Version->new($anotherVersion);
    $this->_compare_to_mvn_version($other);
  }
}

=head2 new

=cut

sub new {
  my ($class, $version) = @_;
  unless ($version) {
    $version = 0;
  }
  $version =~ s/^(\-|\.)/0$1/; #add leading zero when starts by dash or dot
  $version = lc($version); #TODO use locale.EN
  my $this = {};
  bless($this, $class);
  $this->{version} = $version;
  $this->{items} = _normalize(_split_to_lists($version, ()));
  $this;
}

=head2 to_string 

=cut

sub to_string {
  my ($this) = @_;
  _to_normalized_string($this->{items});
}
=head1 AUTHOR

Thomas Cazali, C<< <pandragon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-java-mvn-version at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Java-Maven-Artifact-Version>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Java::Maven::Artifact::Version


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Java-Maven-Artifact-Version>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Java-Maven-Artifact-Version>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Java-Maven-Artifact-Version>

=item * Search CPAN

L<http://search.cpan.org/dist/Java-Maven-Artifact-Version/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Thomas Cazali.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Java::Maven::Artifact::Version
