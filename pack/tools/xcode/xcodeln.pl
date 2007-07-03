#!/usr/bin/perl -w
use strict;
use FileHandle;
use IPC::Open2;
$SIG{CHLD} = 'IGNORE';

while(<>){
  my $pid=open2(*Get,*Put,"xcode -s -q");
  print Put $_; close(Put);
  print <Get>;  close Get;
  kill 9, $pid;
}
exit(0);
