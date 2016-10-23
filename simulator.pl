#!/usr/bin/env perl

use FindBin;
warn "$FindBin::Bin";
use lib "$FindBin::Bin/lib";

use Telegram::Wizard;
use Telegram::Keyboards qw(available_keys parse_reply_markup);
use Config::JSON;
use feature 'say';
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use Data::Dumper;
# use Term::Complete;

my $config = Config::JSON->new('examples/screens.json');

my $w = Telegram::Wizard->new({
	screens_arrayref => $config->get('screens'),
	dyn_kbs_class => 'Telegram::DynamicKeyboards',
	keyboard_type => 'regular',
	max_keys_per_row => 2,
	debug => 1
});

while (1) {

	# $text = Complete('Your input : ', ['foo', 'bar']);

	chomp ($text = <STDIN>);
	# warn $text;

	my $update_simulation = {};
	$update_simulation->{message}{text} = $text;
	$update_simulation->{message}{chat}{id} = 1;

	my $res = $w->process($update_simulation);
	my $msg;

	# warn "Result at simulator.pl : ".Dumper $res;
	# warn Dumper $res;
	
	if (defined $res->{replies}) {
		my $msg = serialize($res->{replies});
	} else {
		$msg = $res;
	}

	say "$msg->{text} ".available_keys(parse_reply_markup($msg->{reply_markup}));
	# say "$msg->{text} ".available_keys($msg->{reply_markup}.' : ');
	# say "$msg->{text} : ".$msg->{reply_markup};
}


sub serialize {
	my $replies = shift;
	warn "All replies:".Dumper $replies;
	my $dt = DateTime->now();

	# $replies->{<screen_name>} eq $text
	if ($replies->{day_select} eq 'tomorrow') {
		$dt->add_duration( DateTime::Duration->new( days => 1) );
	}

	my $h = (split(':',$replies->{morning_time_range_select}))[0];
	$dt->set_hour($h);
	$dt->set_minute(0);
	my $text = $dt->datetime();

	return { text => $text } ;
};
