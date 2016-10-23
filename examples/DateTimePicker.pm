#!/usr/bin/env perl
# DatePicker code based on new credentials

package DateTimePicker;

use common::sense;
use Mojolicious::Lite;
use WWW::Telegram::BotAPI;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use Data::Dumper;

# use Telegram::Keyboards qw(create_one_time_keyboard create_inline_keyboard);
require Telegram::Keyboards;
require Telegram::DynamicKeyboards;
use Telegram::Screens;

use Telegram::Polling qw(get_last_messages);
use Telegram::Sessions;
use Telegram::UpdateParser qw(get_text get_chat_id);

BEGIN { $ENV{TELEGRAM_BOTAPI_DEBUG}=1 };
my $api = WWW::Telegram::BotAPI->new (
    token => '222684756:AAHSkWGC101ooGT3UYSYxofC8x3BD1PT5po'
);
my $Sessions = Telegram::Sessions->new;
my $config = plugin JSONConfig => {file => 'screens.json'};
my $screens = Telegram::Screens->new($config->{screens});
# my $DynamicKeyboards = Telegram::DynamicKeyboards->new;


# sub create_static_keyboard {     ### non-dynamic keyboard creation
# 	my $screen_name = shift;
# 	my $keyboard;
# 	$keyboard = $screens->get_keys_arrayref($screen_name); 
# 	if ($config->{default_keyboard_type} eq 'regular') {
# 		return Telegram::Keyboards::create_one_time_keyboard($keyboard);				
# 	} else { # inline
# 		return Telegram::Keyboards::create_inline_keyboard($keyboard, 1);			
# 	}
# };


### return array. results of functon are used in validation and show screen
sub build_keyboard_array {
	my ($screen, $dyn_kb_args) = @_;
	my $keyboard;

	if ($screens->is_static($screen)) {
		$keyboard = $screens->get_keys_arrayref($screen->{name}); 
	} else {  ##dynamic
		#warn "Go dynamic keyboard";
		my $func_name = $screen->{kb_build_func};
		$keyboard = Telegram::DynamicKeyboards->$func_name($dyn_kb_args);
	}
	#warn "Result of keyboard:".Dumper $keyboard;
	return $keyboard;
}


sub show_screen {
	my ($screen, $chat_id, $dyn_kb_args) = @_;
	my $keyboard = build_keyboard_array($screen, $dyn_kb_args);

	if ($config->{default_keyboard_type} eq 'regular') {
		$keyboard = Telegram::Keyboards::create_one_time_keyboard($keyboard);				
	} else { # inline
		$keyboard = Telegram::Keyboards::create_inline_keyboard($keyboard, 1);			
	}
	
	my $text;
	my $welcome_default = 'welcome';
	if ($screen->{welcome_msg}) {
		$text = $screen->{welcome_msg};
	} else {
		$text = $welcome_default;
	}

	my $msg = { 
		chat_id => $chat_id,
		text => $text,
		reply_markup => $keyboard
	};

	# warn Dumper $msg;.штащ

	$api->sendMessage($msg);
};


# build arrayref of allowed answers
# sub get_valid_answers {
# 	my ($screen, $text) = @_;
# 	if ($screens->is_static($screen)) {
# 		return $screens->get_answers_arrayref($screen->{name});
# 	} else { # dynamic
# 		# my $func_name = $screen->{validation_func};
# 		#Telegram::DynamicValidation->$func_name($dyn_kb_args);
# 		# my $allowed_array = [ 'test'];
# 		my $func_name = $screen->{kb_build_func};
# 		return Telegram::DynamicKeyboards->$func_name($dyn_kb_args);
# 	}
# };


# Example of dynamic keyboard build func
# sub info_build_func {
# 	return Telegram::Keyboards::create_inline_keyboard(['Google', 'Yandex', 'VK'], 2);	
# }
# my $dispatch_table = {
# 	info_build_func => \&info_build_func
# };
# use it as $keyboard = $dispatch_table->{$func_name}->();
# ####


# Call different API depends on input data if previous screen is last
# Function that is working with Session object
# return last mesage depending on session

sub serialize {
	my $chat_id = shift;
	# $scenario[$level];

	# my @scenario = $Sessions->all($chat_id);
	# warn Dumper \@scenario;

	## chat_id specific and 

	# if ($scenario->)

	### mimple
	my $scenario = $Sessions->all_keys_arr($chat_id, 'callback_text');
	warn "Scenario:".Dumper $scenario;
	my $dt = DateTime->now();

	if ($scenario->[2] eq 'tomorrow') {
		$dt->add_duration( DateTime::Duration->new( days => 1) );
	}

	my $h = (split(':',$scenario->[4]))[0];
	$dt->set_hour($h);
	$dt->set_minute(0);

	my $text = 'Serialize: '. join(' -> ',@$scenario);
	$text.= "\n".$dt->datetime();

	$api->sendMessage({ 
		chat_id => $chat_id, 
		text => $text
	});
};

## Brand new universal function
sub serialize2 {
	my $chat_id = shift;
	my $replies = $Sessions->get_replies_hash($chat_id);

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

	$api->sendMessage({ 
		chat_id => $chat_id, 
		text => $text
	});
};













my $last_screen_flag = 0;

Mojo::IOLoop->recurring(1 => sub {
	my $hash = get_last_messages($api); # or just post '/' => sub
	
	while ( my ($chat_id, $update) = each(%$hash) ) {
		# $update as result of Post

		my $chat_id = get_chat_id($update);
		my $text = get_text($update);  				# text data or data from callback query if inline keyboard
		#warn Dumper "Chat ID:".$chat_id.",text:".$text;
		warn "Sessions before Update processing : ".Dumper $Sessions;

		my $screen;
		if ($text =~ "/") {		 # check is it a start of scenario
		# if ($update->{message}{entities}[0]{type} == "bot_command") {
			$screen = $screens->get_screen_by_start_cmd($text);
			$Sessions->del($chat_id);

			if (defined $screen) {	
				$Sessions->start($chat_id);

				app->log->info("Found screen (first): ".$screen->{name});
				show_screen($screen, $chat_id, $text);   # can pass third argument
				$Sessions->update($chat_id, { callback_text => $text, level => $screens->level($screen->{name}), screen => $screen->{name} }); 
				# check isn't it a last screen ?
				if ($screens->is_last_screen($screen->{name})) {
					serialize2($chat_id);
				}

			} else {   ### validate
				$api->sendMessage({ chat_id => $chat_id, text => 'No screen for this command. Check /help or input / for list of available commands' });
			}

		} else {

				#warn "Temp (here must be not empty):".Dumper $Sessions->last($chat_id);
				my $prev_screen_name = $Sessions->last($chat_id)->{screen};  
				#app->log->info("Previous screen: ".$prev_screen_name);
				my $prev_screen = $screens->get_screen_by_name($prev_screen_name);

				#my $allowed_answers = get_valid_answers($prev_screen);
				my $allowed_answers = build_keyboard_array($prev_screen, $text); ### $text is another!

				app->log->info("allowed_answers at prev screen ($prev_screen_name) :".Dumper $allowed_answers);
				#app->log->info("text:".$text.", grep:".grep($text, @$allowed_answers));

				if ($last_screen_flag) {
					$Sessions->update($chat_id, { callback_text => $text, level => $screens->level($screen->{name}), screen => $screen->{name} });
					serialize2($chat_id);
					$Sessions->del($chat_id);
					$last_screen_flag = 0;

				} else {

					if (grep($text, @$allowed_answers)) {  # valid reply


						$screen = $screens->get_next_screen_by_name($prev_screen_name, $text);    #### get_next_screen_by_name
						#warn Dumper $screen;

						if (defined $screen) {	
							app->log->info("Showing screen: ".$screen->{name});
							show_screen($screen, $chat_id, $text);
							$Sessions->update($chat_id, { callback_text => $text, level => $screens->level($screen->{name}), screen => $screen->{name} });
							
							# Can't evaluate user answer on a last screen !
							if ($screens->is_last_screen($screen->{name})) {
								$last_screen_flag = 1;

								# serialize($chat_id);
								# $Sessions->del($chat_id);
							}
						}  else {
							app->log->error("Seems like callback_msg-defined screens are not working");
						}
			
					} else {  # no-valid reply
						$api->sendMessage({ chat_id => $chat_id, text => 'Wrong input' });
					}

				}
		}
	}
});

app->start;
