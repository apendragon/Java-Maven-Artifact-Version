package Java::Maven::Artifact::Version;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Scalar::Util qw/reftype/;
use Hash::Util qw/lock_value/;
use Language::Functional;

=head1 NAME

Java::Maven::Artifact::Version - a perl module for comparing Artifact versions exactly like Maven does.

=head1 VERSION

Version 1.00

see L</Maven version compatibility>.

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Note that this documentation is intended as a reference to the module.

    use Java::Maven::Artifact::Version;


    my $com_version = Java::Maven::Artifact::Version->new(version => '1-alpha');
    my $y = $com_version->compare_to('1-beta'); # $y = -1 
    ...

    my $foo_version = Java::Maven::Artifact::Version->new(version => '1.0');
    my $bar_version = Java::Maven::Artifact::Version->new(version => '1-0-alpha');
    my $x = $bar_version->compare_to($bar_version); # $x = 0
    ...

    my $baz_version = Java::Maven::Artifact::Version->new(version => '1-1.2-alpha');
    my $z = $baz_version->to_string(); # $z = '(1,(1,2,alpha))' 
    ...

=head1 DESCRIPTION

L<Apache Maven|http://maven.apache.org/>  has a peculiar way to compare Artifact versions.
The aim of this module is to exactly reproduce this way in hope that it could be usefull to someone that wants to write utils like SCM hooks. It may quickly ensure an Artifact version respect a grow order without to have to install Java and Maven on the system in charge of this checking.

The official Apache document that describes it is here L<http://docs.codehaus.org/display/MAVEN/Versioning>.
But don't blindly believe everything. Take the red pill, and I show you how deep the rabbit-hole goes.
Because there is a gap between the truth coded in C<org.apache.maven.artifact.versioning.ComparableVersion.java> that can be found L<here|https://github.com/apache/maven/blob/master/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java> and that official document.

Fortunately this module cares about the real comparison differences hard coded in C<ComparableVersion> and reproduces it.

=head2 What are differences between real Maven comparison behaviors and those that are described in the official Maven doc ?

=head3 zero ('C<0>') appending on nude separator char (dot '.' or dash '-')

During parsing if a separator char is encountered and it was not preceded by a stringitem or a listitem, a zero char ('C<0>') is automatically appended.
Then a version that begins with a separator is automatically prefixed by zero.

'C<-1>' will be internally moved to 'C<0-1>'.

'C<1....1>' will be internally moved to 'C<1.0.0.0.1>'.

=head3 The dash separator "B<->" 

The dash separator "B<->" will create a C<listitem> only if it is preceeded by an C<integeritem> and it is followed by a digit.

Then when they say I<1-alpha10-SNAPSHOT => [1,["alpha",10,["SNAPSHOT"]]]> understand it's wrong. 

C<1-alpha10-SNAPSHOT> is internally reprensented by C<[1,"alpha",10,"SNAPSHOT"]>. That has a fully different comparison behavior because no sub C<listitem> is created.

Please note L<zero appending on nude separator|/zero ('C<0>') appending on nude separator char (dot '.' or dash '-')> has been done before C<listitem> splitting. 

Then :

=head3 Normalization

Normalization is a very important behavior in version comparisons but it is not described at all in the official Maven document.
So what is I<normalization> ?
It's kind of reducing version components function.
Its aim is to shoot useless version components in an artifact version. To simplify it, understand C<1.0> must be internally represented by C<1> during comparison.
But I<normalization> appends in specific times during artifact version parsing.

It appends:

=over 4

=item 1. each time a dash 'C<->' separator is preceded and followed by a digit but B<before> any alias substitution

=item 2. at the end of each parsed C<listitem>, then B<after> all alias substitution

=back

And I<normalization> process the current parsed C<listitem> from its current position when normalization is called, back to the beginning of this C<listitem>.

Each encountered C<nullitem> will be shot until a non C<nullitem> is encountered or until the begining of this C<listitem> is reached if all its items are nullitems. 
In this last case precisely, the empty C<listitem> will be shot except if it is the main one.

Then understand :

=over 4

=item * C<1.0.alpha.0> becomes (1,0,alpha) #because when the main C<listitem> parsing has ended, normalization has been called. Last item was 0, 0 is the nullitem of integeritem, then it has been shooted. Next last item was alpha that is note a nullitem then normalization process stopped.

=item * C<1.0-final-1> becomes (1,,1) #because 0 preceded a dash and because final has been substituted by '' and the last item is not a C<nullitem>

=item * C<0.0.ga> becomes () # because 'ga' has been substituted by '' and when the C<listitem> has been normalized at the end, all items where C<nullitem>s

=item * C<final-0.1 becomes> (,0,1) # because normalization has not been called after first dash because it was not been preceded by a digit.

=back

If you told me I<WTF ?>, I would answer I am not responsible of drug consumption...

In C<org.apache.maven.artifact.versioning.ComparableVersion.java>, the representation of normalized version is only displayable with the call of C<org.apache.maven.artifact.versioning.ComparableVersion.ListItem.toString()> private method on the main C<ListItem>.

Comma "C<,>" is used as items separator, and enclosing braces is used to represent C<ListItem>.

For example:
   in Java world C<org.apache.maven.artifact.versioning.ComparableVersion.ListItem.toString()> on C<"1-0.1"> gives C<"(1,(0,1))">.

L</to_string> method reproduces this behavior for the whole set C<Java::Maven::Artifact::Version>.

    $v = Java::Maven::Artifact::Version->new(version => '1-0.1');
    $s = $v->to_string(); # $s == '(1,(O,1))'

=cut

use constant {
  _ALPHA        => 'alpha',
  _BETA         => 'beta', 
  _DEBUG        => 0,
  _INTEGER_ITEM => 'integeritem',
  _LIST_ITEM    => 'listitem',
  _MILESTONE    => 'milestone',
  _NULL_ITEM    => 'nullitem',
  _RC           => 'rc',
  _SNAPSHOT     => 'snapshot',
  _SP           => 'sp',
  _STRING_ITEM  => 'stringitem',
  _UNDEF        => 'undef'
};

=head1 SUBROUTINES/METHODS

=cut

sub _identify_scalar_item_type {
  my ($scalar) = @_;
  $scalar =~ m/^\d+$/ ? _INTEGER_ITEM : _STRING_ITEM;
}

sub _getref {
  my ($var) = @_;
  (ref($var) || not defined($var)) ? $var : \$var; # var may already be a ref
}

sub _is_nullitem {
  my ($item) = @_;
  (not defined($item)) ? 1 : _UNDEF eq reftype(_getref($item));
}

sub _reftype {
  my ($item) = @_;
  _is_nullitem($item) ? _UNDEF : reftype(_getref($item));
}

sub _identify_item_type {
  my ($item) = @_;
  my $types = {
    _UNDEF()  => sub { _NULL_ITEM }, 
    'SCALAR'  => sub { _identify_scalar_item_type($item) }, 
    'ARRAY'   => sub { _LIST_ITEM },
    _DEFAULT_ => sub { die "unable to identify item type of item $item ." }
  };
  my $t = _reftype($item);  
  print("_identify_item_type($t)\n") if (_DEBUG);
  exists $types->{$t} ? $types->{$t}->() : $types->{_DEFAULT_}->();
}

sub _compare_integeritem_to {
  my ($integeritem, $item) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub {
      print("comparing $integeritem to nullitem\n") if (_DEBUG); 
      $integeritem =~ m/^0+$/ ? 0 : 1;
    },
    &_LIST_ITEM    => sub {
      print("comparing $integeritem to listitem\n") if (_DEBUG); 
      1;
    },
    &_INTEGER_ITEM => sub {
      print("comparing $integeritem to $item\n") if (_DEBUG); 
      $integeritem <=> $item;
    },
    &_STRING_ITEM  => sub {
      print("comparing $integeritem to stringitem\n") if (_DEBUG); 
      1;
    }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_items {
  my ($item1, $item2) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub {
      print("_compare_items(nullitem, ?)\n") if (_DEBUG); 
      return 0 unless (defined($item2));
      _compare_items($item2, undef) * -1;
    },
    &_LIST_ITEM    => sub {
      print("_compare_items(listitem, ?)\n") if (_DEBUG); 
      _compare_listitem_to($item1, $item2);
    },
    &_INTEGER_ITEM => sub {
      print("_compare_items(integeritem, ?)\n") if (_DEBUG);
      _compare_integeritem_to($item1, $item2);
    },
    &_STRING_ITEM  => sub {
      print("_compare_items(stringitem, ?)\n") if (_DEBUG);
      _compare_stringitem_to($item1, $item2);
    }
  };
  $dispatch->{_identify_item_type($item1)}->();
}

sub _compare_listitem_to {
  my ($listitem, $item) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub { _compare_listitem_to_nullitem($listitem) },
    &_LIST_ITEM    => sub { _compare_listitems($listitem, $item) },
    &_INTEGER_ITEM => sub { -1 },
    &_STRING_ITEM  => sub { 1 }
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
  die("parameter is not a Java::Maven::Artifact::Version") unless ($anotherVersion->isa('Java::Maven::Artifact::Version')); 
  _compare_listitems($this->{items}, $anotherVersion->{items});
}

sub _compare_stringitem_to {
  my ($stringitem, $item) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub { _compare_stringitem_to_stringitem($stringitem, $item) },
    &_LIST_ITEM    => sub { _compare_listitem_to($item, $stringitem) * -1 },
    &_INTEGER_ITEM => sub { _compare_integeritem_to($item, $stringitem) * -1 },
    &_STRING_ITEM  => sub { _compare_stringitem_to_stringitem($stringitem, $item) }
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

sub _append_zero {
  my ($string) = shift;
#  $string =~ s/^(\-|\.)/0$1/;           #zero appending when starts by dash or dot
  $string =~ s/(\-|\.)(\-|\.)/${1}0$2/g; #or when 1 separator immediately succeeds an other one
  $string;
}

# _split_to_items must only be called when version has been splitted into listitems
# Then it works only on a single listitem
sub _split_to_items {
  my ($string) = @_;
  my @items = ();
  my @tonormalize = _split_to_to_normalize($string);
  #at this time we must replace aliases with their values 
  my $closure = sub {
    my ($i) = shift;
    $i = _replace_special_aliases($i); #must be replaced BEFORE items splitting
    my @xs = split(/\-|\./, $i);
    my @xsp = map({ _replace_alias($_) } @xs); #must be replaced after items splitting
    push(@items, @{_normalize(\@xsp)} );
  };
  map { $closure->($_) } @tonormalize;
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
  return _NULL_ITEM unless defined($stringitem);
  return _ALPHA     if $stringitem =~ m/^(alpha|a\d+)$/;
  return _BETA      if $stringitem =~ m/^(beta|b\d+)$/;
  return _MILESTONE if $stringitem =~ m/^(milestone|m\d+)$/;
  return _RC        if $stringitem =~ m/^rc$/;
  return _SNAPSHOT  if $stringitem =~ m/^snapshot$/;
  return _NULL_ITEM if $stringitem =~ m/^$/;
  return _SP        if $stringitem =~ m/^sp$/;
  '_DEFAULT_';
}

sub _substitute_to_qualifier {
  my ($stringitem) = @_;
  my $qualifier_cmp_values = {
    &_ALPHA     => '0',
    &_BETA      => '1',
    &_MILESTONE => '2',
    &_RC        => '3',
    &_SNAPSHOT  => '4',
    &_NULL_ITEM => '5',
    &_SP        => '6',
    _DEFAULT_  => $stringitem ? "7-$stringitem" : '7-' #yes they really did that in ComparableVersion...
  };
  $qualifier_cmp_values->{_identify_qualifier($stringitem)};
}


sub _to_normalized_string {
  my ($items) = @_;
  my $s = '(';
  my $append = sub {
    my ($i) = shift; 
    ref($i) eq 'ARRAY' ? $s .= _to_normalized_string($i) : ($s .= "$i");
    $s .= ',';
  };
  map { $append->($_) } @$items ;
  chop($s) if (length($s) > 1);
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
  $version = lc($version); #TODO use locale.EN
  my $this = {};
  bless($this, $class);
  $this->{version} = $version;
  $this->{items} = _normalize(_split_to_lists($version, ()));
  $this;
}

=head2 to_string 

will return the normalized version representation (see L</"Normalization">)

    $v = Java::Maven::Artifact::Version->new(version => '1.0-final-1');
    $s = $v->to_string(); # $s == '(1,(,1))'

Then if you want to get the original set version use the C<version> attribute instead :

    $s = $v->{version}; # $s == '1.0-final-1'

And if you want to get the inside version C<listitem> use the C<items> attribute :

    $s = $v->{items}; # $s == [1,['',1]]

=cut

sub to_string {
  my ($this) = @_;
  _to_normalized_string($this->{items});
}

=head1 Maven version compatibility

This version is fully compatible with the C<org.apache.maven.artifact.versioning.ComparableVersion.java> behavior of C<org.apache.maven:maven-artifact:3.2.2> embedded with Maven 3.2.2

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

Thanks to Bruno Villegas for his english review.

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
