#!/usr/local/bin/perl -w
$|++;
use strict;
my @formats = qw(CSV Pipe Tab Fixed Paragraph ARRAY);
eval {
  require XML::Parser;
  require XML::Twig;
};
unshift @formats,'XML' unless $@;
undef $@;
eval {
  require HTML::Parser;
  require HTML::TableExtract;
  require CGI;
};
push @formats,'HTMLtable' unless $@;

for my $driver('AnyData') {
  print "\n$driver\n";
  for my $format( @formats ) {
      printf  "  %10s ... ", $format;
      printf "%s!\n" , test($driver,$format);
  }
}

sub test {
    my($driver,$format)=@_;
    return $driver =~ /dbd/i
        ? test_dbd($format)
        : test_ad($format);
}

sub test_ad {
 use AnyData;
 my $file = 'AnyData_test_db';
 my $format = shift;
 my $mode = 'o';
 my $flags = {cols=>'name,country,sex',pattern=>'A5 A8 A3'};
 my $table = adTie( $format,$file, $mode, $flags ); # create a table
 $table->{Sue} = {country=>'fr',sex=>'f'};          # insert rows
 $table->{Tom} = {country=>'fr',sex=>'f'};
 $table->{Bev} = {country=>'en',sex=>'f'};
 $table->{{ name=>'Tom'}} = {sex=>'m'};             # update a row
 delete $table->{Bev};                              # delete a row
 adExport($table,$format,$file) if $format =~ /XML|HTMLtable/;                      # save table to disk
 $flags = {pattern=>'A5 A8 A3'};
 if ($format ne 'ARRAY') {
 undef $table;                                      # remove table from memory
 $table = adTie( $format,$file, 'r', $flags );      # read table from disk
 }
 return "Failed single select"
    unless 'f' eq $table->{Sue}->{sex};             # select a single value
 my $tstr;
 while ( my $person = each %$table ) {              # select mulitple rows
    $tstr .= $person->{name}
       if $person->{country} eq 'fr';
 }
 return "Failed multiple select"
    unless 'SueTom' eq $tstr;
 return "Failed names" unless 'namecountrysex' eq join '',adNames($table);
 return "Failed rows"  unless 2 == adRows($table);
 if ($format ne 'ARRAY') {
 my $str = adConvert('ARRAY',[["a","b"],[1,2]],$format,undef,undef,$flags);       # convert to
 $str =~ s/\s+/,/ if $format eq 'Fixed';
 my $ary = adConvert($format,[$str],'ARRAY',undef,$flags); # convert from
 return "Failed converting" unless $ary->[0]->[0] eq 'a';
 }
return 'ok';
}

sub test_dbd {}

__END__
