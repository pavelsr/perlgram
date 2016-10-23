#!/usr/bin/env perl

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;


my $dt = DateTime->now;
warn $dt->datetime();

### tomorrow

my $duration_object = DateTime::Duration->new( days => 1);
$dt->add_duration( $duration_object );
warn $dt->datetime();


### today but particular hour
$dt = DateTime->now;
$dt->set_hour('22');
warn $dt->datetime();


my $text = '22:00';

my $h = (split(':',$text))[0];
warn $h;

# set_day()
# $dt->set_hour()
