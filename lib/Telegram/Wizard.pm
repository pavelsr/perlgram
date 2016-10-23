# Superclass that return message to send via api
package Telegram::Wizard;

use common::sense;
use Data::Dumper;
use Telegram::Screens;
use Telegram::Sessions;
use Telegram::UpdateParser qw(get_text get_chat_id);
use Telegram::Keyboards qw(create_one_time_keyboard create_inline_keyboard);
use Module::Load;

# Example of usage
# { screens_arrayref => [{},{}, ... , {}], 
#	dyn_kbs_class=>'Test::Class',     
#   serialize_func => \&test_func().
#   keyboard_type => 'inline'  # regular by default,
#   default_welcome_msg => 'no msg',
#	debug => '1'
# }

sub new {
    my ($class, $params) = @_;
    my $h = {};
    $h->{sessions} = Telegram::Sessions->new;
    $h->{screens} = Telegram::Screens->new($params->{screens_arrayref});
    
    my $dyn_kb_class = $params->{dyn_kbs_class};
    autoload $dyn_kb_class;
    # warn $dyn_kb_class;
    $h->{dynamic_keyboards_class} = $dyn_kb_class->new;
    $h->{last_screen_flag} = 0;
    my $defaults = {
		keyboard_type => 'regular',
		default_welcome_msg => 'warning: welcome_msg for this screen is not set',
		debug => 0,
		max_keys_per_row => 2
	};
    $class->defaults($defaults, $h, $params);

 #    if (!(defined $params->{keyboard_type})) {
 #    	$h->{keyboard_type} = 'regular';
 #    } else {
 #    	$h->{keyboard_type} = $params->{keyboard_type};
	# }

    bless $h, $class;
    return $h;
}

# Set defaults for not obligatory parameters
sub defaults {
	my ($self, $defaults, $class_hash, $params_hash) = @_;
	for my $key (keys %$defaults) {
		if (!(defined $params_hash->{$key})) {
    		$class_hash->{$key} = $defaults->{$key};
	    } else {
	    	$class_hash->{$key} = $params_hash->{$key};
		}
	}
}

sub get_screen {
	my ($self, $text, $chat_id) = @_;
	my $screen;
	if ($text =~ "/") {   # start command
		# $self->{sessions}->del($chat_id);
		$screen = $self->{screens}->get_screen_by_start_cmd($text);
	} else {
		my $prev_screen_name = $self->{sessions}->last($chat_id)->{screen};  
		my $prev_screen = $self->{screens}->get_screen_by_name($prev_screen_name);
		$screen = $self->{screens}->get_next_screen_by_name($prev_screen_name, $text);
	}
	return $screen;
}

sub build_keyboard_array {
	my ($self, $screen, $dyn_kb_args) = @_;
	my $keyboard;
	#warn "build_keyboard_array() screen argument (line 78) : ".Dumper $screen;
	if ($self->{screens}->is_static($screen)) {
		$keyboard = $self->{screens}->get_keys_arrayref($screen->{name}); 
	} else {  ##dynamic
		my $func_name = $screen->{kb_build_func};
		$keyboard = $self->{dynamic_keyboards_class}->$func_name($dyn_kb_args);
	}
	return $keyboard;
}


# Build msg
sub build_msg {
	my ($self, $screen, $chat_id, $dyn_kb_args) = @_;
	#warn "build_msg() screen argument (line 92):". Dumper $screen;
	my $keyboard = $self->build_keyboard_array($screen, $dyn_kb_args);
	if ($self->{keyboard_type}  eq 'regular') {
		$keyboard = create_one_time_keyboard($keyboard, $self->{max_keys_per_row});				
	} else { # inline
		$keyboard = create_inline_keyboard($keyboard, $self->{max_keys_per_row});			
	}
	
	my $welcome_text;
	if ($screen->{welcome_msg}) {
		$welcome_text = $screen->{welcome_msg};
	} else {
		$welcome_text = $self->{default_welcome_msg};
	}

	my $msg = { 
		chat_id => $chat_id,
		text => $welcome_text,
		reply_markup => $keyboard
	};

	return $msg;
};

sub update_session {
	my ($self, $chat_id, $text, $screen) = @_;
	if ($screen) {
		$self->{sessions}->update($chat_id, { 
			callback_text => $text, 
			level => $self->{screens}->level($screen->{name}), 
			screen => $screen->{name} }
		);
	} else { # case of final reply in scenario
		$self->{sessions}->update($chat_id, { callback_text => $text });
	}
}


sub process {
	my ($self, $update) = @_;
	my $msg = {};  # to return 

	my $chat_id = Telegram::UpdateParser::get_chat_id($update);
	my $text = Telegram::UpdateParser::get_text($update);

	

	if ($self->{last_screen_flag}) {
		my $prev_screen_name = $self->{sessions}->last($chat_id)->{screen};  
		my $prev_screen = $self->{screens}->get_screen_by_name($prev_screen_name);
		# process Update after last screen
		$self->update_session($chat_id, $text);
		my $replies = $self->{sessions}->get_replies_hash($chat_id);
		$self->{last_screen_flag} = 0;
		warn "Session for this chat_id:".Dumper $self->{sessions}->all($chat_id);
		$self->{sessions}->del($chat_id);
		return $replies;
	}

	warn "Session for this chat_id : ".Dumper $self->{sessions}->all($chat_id);

	my $screen = $self->get_screen($text, $chat_id);

	if (defined $screen) {

		# warn Dumper $screen;

		my $prev_screen_name;
		my $allowed_answers;


		#########################################
		if ($self->{screens}->level($screen->{name}) == 0) {
			$self->{sessions}->start($chat_id);
			warn "session start!";
		} else {
			# validate if no first screen
			$prev_screen_name = $self->{sessions}->last($chat_id)->{screen};  
			my $prev_screen = $self->{screens}->get_screen_by_name($prev_screen_name);
			#warn "prev._screen:".$prev_screen_name;
			#warn "prev screen data:".Dumper $prev_screen;
			$allowed_answers = $self->build_keyboard_array($prev_screen, $text); # use is_static
			#warn "Validation: allowed_answers :".join(',', @$allowed_answers);
		}
		#########################################


		if ($self->{screens}->is_last_screen($screen->{name})) {
			$self->{last_screen_flag} = 1;
		}


		#########################################
		if ($self->{screens}->level($screen->{name}) == 0) {
			#warn "level 0!";
			# first screen
			$msg = $self->build_msg($screen, $chat_id, $text);
			$self->update_session($chat_id, $text, $screen);
			return $msg;

		} else {
			#warn "Allowed answers (line 186):".Dumper $allowed_answers;
			if (grep($text, @$allowed_answers)) {
				$msg = $self->build_msg($screen, $chat_id, $text);
				$self->update_session($chat_id, $text, $screen);
				return $msg;
			} else {
				$msg = { chat_id => $chat_id, text => 'No valid reply!'};
				return $msg;
			}
		}
		#########################################


	} else {
		# Last screen of no screen for this callback
		$msg = { chat_id => $chat_id, text => 'No screen found! Check your config.json'};
		return $msg;
	}

}

1;