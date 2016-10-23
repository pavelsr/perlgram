package Telegram::Keyboards;

use JSON::MaybeXS;
use common::sense;

use Exporter qw(import);
our @EXPORT_OK = qw(create_one_time_keyboard create_inline_keyboard parse_reply_markup available_keys);

my $is_inline = 0;   # 1 = inline / 0 = one item at column

# Create a regular keyboard
# For using with reply_markup param of API sendMessage method
# Input = Array
sub create_one_time_keyboard {
	my ($keys, $k_per_row) = @_;
	if (!(defined $k_per_row)) { 
		if ($is_inline) { $k_per_row = scalar @$keys } else { $k_per_row = 1 };
	}

	my @keyboard;
	my @row;
	for my $i (1 .. scalar @$keys) { 
		my $el = $keys->[$i-1];
		push @row, $el;
		if ((($i % $k_per_row) == 0) || ($i == scalar @$keys)) {
			push (@keyboard, [ @row ]);
			@row=();
		}
	}

	my %rpl_markup = (
		keyboard => \@keyboard,
		one_time_keyboard => JSON::MaybeXS::JSON->true
		);
	return JSON::MaybeXS::encode_json(\%rpl_markup);
}

# Create an inline keyboard wuth same callback_data as text
# For using with reply_markup param of API sendMessage method
# Input = Array

sub create_inline_keyboard {
	my ($keys, $k_per_row) = @_;
	if (!(defined $k_per_row)) { 
		if ($is_inline) { $k_per_row = scalar @$keys } else { $k_per_row = 1 };
	}
	my @keyboard;
	my @row;
	for my $i (1 .. scalar @$keys) { 
		my $el = $keys->[$i-1];
		push @row, { "text" => $el, "callback_data" => $el };
		if ((($i % $k_per_row) == 0) || ($i == scalar @$keys)) {
			push (@keyboard, [ @row ]);
			@row=();
		}
	}
	my %rpl_markup = (
		inline_keyboard  => \@keyboard
	);
	return JSON::MaybeXS::encode_json(\%rpl_markup);
}

# For simulator.pl
# return string of possible answers

sub available_keys {
	my $arr = shift;
	# warn Dumper $reply_markup;
	# my $arr = parse_reply_markup($reply_markup);
	my $text = '[ ';
	$text.= join(' | ',@$arr);
	$text.= ' ]';
	return $text;
}


sub parse_reply_markup {
	my $reply_markup = shift;
	my $data_structure = decode_json($reply_markup);
	my @res;
	my @keyboard;
	my $is_inline_flag = 0;

	if (defined $data_structure->{inline_keyboard}) {
		@keyboard = {$data_structure->{inline_keyboard}};
		$is_inline_flag = 1;
	} elsif (defined $data_structure->{keyboard}) {
		@keyboard = @{$data_structure->{keyboard}};
	} else {
		warn "reply_markup structure isn't recognized";
		return undef;
	}

	for my $i (@keyboard) {
		for (@$i) {
			if ($is_inline_flag) {
				push @res, $_->{text};
			} else {
				push @res, $_;
			}
		}
	}

	return \@res;
}




# need to implement:
# build_optimal()
# build_optimal_according_order()

1;