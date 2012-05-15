#!/usr/bin/env perl

use DateTime;
use File::Basename;
use Image::Magick;
use Log::Message::Simple;
use strict;

# debug flag
my $debug = 1;

my $in_name = shift;
debug("Input name: $in_name", $debug);

my $out_dir = shift // '.';
$out_dir =~ s|/$||;
debug("Output directory: $out_dir", $debug);

my $bg_filename = 'background.png';

my ($crop_w, $crop_h) = (386, 340);
my ($translate_x, $translate_y) = (62, 62);
my $crop_geometry = geometry($crop_w, $crop_h, $translate_x, $translate_y);

my ($output_w, $output_h) = (671, 489);
my $output_geometry = geometry($output_w, $output_h);

my $overlay_width = 512;
my $ratio = 438/495; # found by stretching it over google maps in image editor
my $overlay_geometry = geometry($overlay_width,  $ratio * $overlay_width);

my $overlay_trans_x = 255;
my $overlay_trans_y = 315;
my $overlay_trans_geometry = geometry(undef, undef, $overlay_trans_x, $overlay_trans_y);

my ($out_w, $out_h) = (800, 600);
my ($out_off_x, $out_off_y) = (173 ,235);
my $out_crop_geometry = geometry($out_w, $out_h, $out_off_x, $out_off_y);

my ($label_x, $label_y) = (445, 550);
my $label_geometry = geometry(undef, undef, $label_x, $label_y);
my $label_size = 18;

my $background;
$background = Image::Magick->new;
$background->Read($bg_filename);

if($in_name =~ m/-/) {
  msg("Processing file names listed on stdin", $debug);
  while(<STDIN>) {
    chomp;
    process_image($_);
  }
} elsif (-f $in_name) {
  process_image($in_name);
} elsif (-d $in_name) {
  $in_name =~ s|/$||;
  msg("Processing all .png files in $in_name", $debug);
  my $dir;
  opendir($dir, $in_name) or die "can't opendir $in_name: $!";
  while (defined(my $file = readdir($dir))) {
    my $file_name = "$in_name/$file";
    if($file_name =~ m/.png$/) {
      process_image($file_name);
    }
  }
  closedir($dir);
} 
 

sub process_image {
  my $in_path = shift;
  msg("Processing file $in_path", $debug);
  my $bixi_data = Image::Magick->new;
  my $filename = basename($in_path);
  my $out_path = "$out_dir/$filename";

  my $time_stamp = basename($in_path, '.png');

  my $dt_label = Image::Magick->new();
  $dt_label->SetAttribute(fill => 'red', background => '#0000000000000000'
    , font => '/Library/Fonts/Andale Mono.ttf', pointsize => $label_size);
  my $label = 'label:' . dt_str($time_stamp);
  $dt_label->Read($label);

  my $err;

  # read in the bixi bike data
  $err = $bixi_data->Read($in_path);
  die $err if $err;

  #crop out axes
  $err = $bixi_data->Crop(geometry => $crop_geometry);
  die $err if $err;

  # adjust color and opacity
  my ($w, $h) = $bixi_data->Get('columns', 'rows');
  my $overlay = Image::Magick->new(size => geometry($w, $h));
  $err = $overlay->Read('canvas:red');
  die $err if $err;

  $err = $bixi_data->Negate();
  die $err if $err;
  $err = $overlay->Composite(image => $bixi_data, compose => 'CopyOpacity');
  die $err if $err;

  # create background map image with correct dimensions to overlay onto
  my $bg = Image::Magick->new;
  $err = $bg->Read($bg_filename);
  die $err if $err;

  # resize and overlay data onto map image
  $err = $overlay->Resize(geometry => $overlay_geometry);
  die $err if $err;
  $err = $bg->Composite(image => $overlay, geometry => $overlay_trans_geometry);
  die $err if $err;

  # crop to output dimensions
  $bg->Crop(geometry => $out_crop_geometry);

  # add label
  $bg->Composite(image => $dt_label, geometry => $label_geometry);

  $err = $bg->Write($out_path);
  die $err if $err;

  # clear the image objects out; unsure if this is necessary
  @$bg = ();
  @$overlay = ();
  @$bixi_data = ();
}

sub geometry {
  my $x = shift;
  my $y = shift;
  my $x_off = shift;
  my $y_off = shift;

  my $dims = $x . 'x' . $y if defined $x && defined $y;
  my $offsets = sprintf "%+d%+d", $x_off, $y_off if defined $x_off && defined $y_off;

  return $dims . $offsets;
}

sub dt_from_unix {
  my $unix_time = shift;
  $unix_time /= 1000 if $unix_time > 2_000_000_000; # dates are circa 2012 in s or ms from epoch
  my $dt = DateTime->from_epoch( epoch => $unix_time );
  $dt->set_time_zone( 'America/Montreal' );
}

sub dt_str { 
  my $unix_time = shift;
  my $dt = dt_from_unix($unix_time);
  return sprintf "%s\n%02d:%02d", $dt->ymd(), $dt->hour, $dt->minute;
}
