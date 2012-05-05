#!/usr/bin/env perl
use Log::Message::Simple;
use File::Basename;
use Image::Magick;
use strict;

# debug flag
my $debug = 1;

my $in_name = shift;
debug("Input name: $in_name", $debug);

my $out_dir = shift // '.';
$out_dir =~ s|/$||;
debug("Output directory: $out_dir", $debug);

my $bg_filename = 'background.png';
my $crop_w = 386;
my $crop_h = 340;
my $translate_x = 62;
my $translate_y = 62;
my $crop_geometry = $crop_w . 'x' . $crop_h . '+' . $translate_x . '+' . $translate_y;
my $ratio = 438/495;
my $overlay_width = 512;
my $output_geometry = $overlay_width . 'x' . $ratio * $overlay_width;

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
    process_image("$in_name/$file");
  }
  closedir($dir);
} 
 

sub process_image {
  my $in_path = shift;
  msg("Processing file $in_path", $debug);
  my $bixi_data = Image::Magick->new;
  my $filename = basename($in_path);
  my $out_path = "$out_dir/$filename";

  # read in the bixi bike data
  $bixi_data->Read($in_path);

  #crop out axes
  $bixi_data->Crop(geometry => $crop_geometry);

  # adjust color and opacity
  my ($w, $h) = $bixi_data->Get('columns', 'rows');
  my $overlay_geometry =  $w . 'x' . $h . "\n";
  my $overlay = Image::Magick->new(size => $overlay_geometry);
  $overlay->Read('canvas:red');

  $bixi_data->Negate();
  $overlay->Composite(image => $bixi_data, compose => 'CopyOpacity');

  # resize and overlay map image
  $overlay->Resize(geometry => $output_geometry);
  $overlay->Composite(geometry => '-66-62', image => $background, compose => 'DstOver');

  $overlay->Write($out_path);
}
