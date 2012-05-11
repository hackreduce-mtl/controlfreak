#!/usr/bin/env perl

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

my $out_trans_x = 255;
my $out_trans_y = 315;
my $out_trans_geometry = geometry(undef, undef, $out_trans_x, $out_trans_y);

my $background;
$background = Image::Magick->new;
$background->Read($bg_filename);


if (-f $in_name) {
  process_image($in_name);
 }
if (-d $in_name) {
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
  $err = $bg->Composite(image => $overlay, geometry => $out_trans_geometry);
  die $err if $err;

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
