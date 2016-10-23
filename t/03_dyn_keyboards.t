#!/usr/bin/env perl

use Telegram::DynamicKeyboards;
use Class::Inspector;

# use Test::Simple tests => 4;
use Data::Dumper;
my $methods = Class::Inspector->methods('Telegram::DynamicKeyboards', 'public' );
# warn "Available methods:".	Dumper $methods;

my $func_name = 'info_build_func';


### Opt 1 - working
# my $kbs = Telegram::DynamicKeyboards->new;
# $func_name = 'info_build_func';
# warn Dumper $kbs->$func_name();


### Opt1
my $a = Telegram::DynamicKeyboards->$func_name;
warn Dumper $a;


my $dyn_kb_args = 'morning';

$func_name = 'dynamic1_build_func';
# warn Dumper $kbs->$func_name($dyn_kb_args);


my $a = Telegram::DynamicKeyboards->$func_name($dyn_kb_args);
warn Dumper $a;




# warn Dumper $kbs;

# warn Dumper Telegram::DynamicKeyboards::dynamic1_build_func('morning');

# # warn Dumper $kbs->info_build_func();
# warn Dumper $kbs->$func_name($dyn_kb_args);


# my $func_name = 'info_build_func';
# warn Dumper $kbs->info_build_func();