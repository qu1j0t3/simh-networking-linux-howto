#!/usr/bin/perl -w
use strict;

# Based on mkdisttap.pl
# ftp://ftp.mrynet.com/pub/os/PUPS/PDP-11/Boot_Images/2.11_on_Simh/211bsd/mkdisttap.pl

#
# $Id: mkdisttap.pl,v 1.1 2006/09/16 23:33:46 kirk Exp kirk $
#

# Based on the example in the HOWTO using dd.  Does not work!
# add_file("cat mtboot mtboot boot |", 512);

# Based on the maketape.c program and the maketape.data data file.
add_file("stand", 512);
end_file();
add_file("miniroot", 10240);
end_file();
add_file("rootdump", 10240);
end_file();
add_file("usr.tar", 10240);
end_file();
add_file("srcsys.tar", 10240);
end_file();
add_file("src.tar", 10240);
end_file();
end_file();

sub end_file {
  print "\x00\x00\x00\x00";
}

sub add_file {
  my($filename, $blocksize) = @_;
  my($block, $bytes_read, $length);

  open(FILE, $filename) || die("Can't open $filename: $!");
  while($bytes_read = read(FILE, $block, $blocksize)) {
    if($bytes_read < $blocksize) {
      $block .= "\x00" x ($blocksize - $bytes_read);
      $bytes_read = $blocksize;
    }
    $length = pack("V", $bytes_read);
    print $length, $block, $length;
  }
  close(FILE);
}
