package Telegram::Screens;

use common::sense;
use Data::Dumper;

# Create a Screens
# Parameter = hash
# State automat
# Methods starting from _ are private

## Функция проверки json на правильность!!!!
# Каждый screen item должен иметь уникальный name и parent
# Не может быть два элемента с одинаковым parent, кроме особых случаев
# Особый случай: у двоих элементов parent может быть одинаков если parent_answ разные 
# (вопрос - как проводить валидацию в случае динимаческих итемов?)

sub new {
    my $class = shift;
    my $s = {};
    $s->{scrns} = shift; # Array with all screens
    bless $s, $class;
    return $s; 
}

### Simple getters and setters

sub _get_all_screens {
    my $self = shift;
    return $self->{scrns};
}

###

sub get_screen_by_name {
	my ($self, $screen_name) = @_;
	for (@{$self->_get_all_screens}) {
		if ($_->{name} eq $screen_name) {
			return $_;
		}
	}
	return undef;
}

# $text field is 
sub get_next_screen_by_name {
	my ($self, $screen_name, $text) = @_;
	my @candidates_to_return = grep ($_->{parent} eq $screen_name, @{$self->_get_all_screens});
	if (scalar @candidates_to_return == 1) {
		return $candidates_to_return[0];
	} 
	elsif (scalar @candidates_to_return > 1) {
		if ($text) {
			for (@candidates_to_return) {
				if ($_->{callback_msg} eq $text) {
					return $_;
				}
			}
		} else {
			if ($candidates_to_return[0]->{callback_msg}) {
				# patch for is_last screen() function, it has only one argument ($screen name) and must "screen" object
				return $candidates_to_return[0];
			} else {
				# two or more child screens with same parent and without callback_msg specific  
				die "wrong json file";
			}
		}
	} else {
		return undef;
	}


	# 	if ($text) {
	# 		if (($_->{parent} eq $screen_name) && ($_->{parent_answ} eq $text)) {
	# 			return $_;
	# 		}
	# 	} else {
	# 		if ($_->{parent} eq $screen_name) {
	# 			return $_;
	# 		}
	# 	}
	# }
	#return undef;
}

sub get_prev_screen_by_name {
	my ($self, $screen_name) = @_;
	for (@{$self->_get_all_screens}) {
		if ($_->{name} eq $screen_name) {
			return $self->get_screen_by_name($_->{parent});
		}
	}
	return undef;
}

sub level {
	my ($self, $screen_name) = @_;
	my $i = 0;
	my $prev_screen = $self->get_prev_screen_by_name($screen_name);

	while (defined $prev_screen )  {
		$i++;
		$prev_screen = $self->get_prev_screen_by_name($prev_screen->{name});
	}
	return $i;
}

sub get_screen_by_start_cmd {
	my ($self, $cmd) = @_;
	for my $s (@{$self->_get_all_screens}) {
		if ($s->{start_command} eq $cmd) {   # don't use eq here
			return $s;
		}
	}
	return undef;
}

sub is_last_screen {
    my ($self, $screen_name) = @_;
    if (defined $self->get_next_screen_by_name($screen_name)) {
    	return 0;
    }
    return 1;
}

sub is_first_screen {
    my ($self, $screen_name) = @_;
    if (defined $self->get_prev_screen_by_name($screen_name)) {
    	return 0;
    }
    return 1;
}

sub is_static {
	my ($self, $screen) = @_;
	if ($screen->{keyboard}) {
		return 1;
	} else {
		return 0;
	}
}

sub get_keys_arrayref {
	my ($self, $screen_name) = @_;
	my @a;
	for (@{$self->get_screen_by_name($screen_name)->{keyboard}}) {
		push @a, $_->{key};
	}
	return \@a;
}

sub get_answers_arrayref {
	my ($self, $screen_name) = @_;
	my @a;
	for (@{$self->get_screen_by_name($screen_name)->{keyboard}}) {
		push @a, $_->{answ};
	}
	return \@a;
}


### For next message
sub get_answ_by_key {
	my ($self, $screen_name, $msg) = @_;
	my $s = $self->get_screen_by_name($screen_name)->{keyboard};
	for (@$s) {
		if ($msg eq $_->{key}) {
			return $_->{answ};
		}
	}
	return undef;
}



# Getter: Highest-level function
# Analyse text and current screen
# Use get_next_screen_by_name and get_screen_by_start_cmd
# Return hash or undef
# You can use:
# $screens->next_screen('/start') then $screens->current or my $s = screens->next_screen('/start');
# Resolve issue with first and second call
# CAN be transfered to Telegram::StateMachine

# sub find_screen {
# 	my ($self, $text) = @_;

# 	my $by_cmd = $self->_get_screen_by_start_cmd($text);

# 	if ($by_cmd) {
# 		#app->log->info("Found screen by start command :".$by_cmd->{name});
# 		$self->_set_curr_screen($by_cmd);
# 		#warn "find_screen(), by cmd : ".Dumper $self->current;
# 		return $self->current;
# 		#return $by_cmd;
# 	}

# 	my $by_name = $self->_get_next_screen_by_name($self->current->{name});
	
# 	if ($by_name) {
# 		#warn "find_screen(), by name : ".Dumper $by_name;
# 		$self->_set_curr_screen($by_name); 
# 		return $self->current;
# 	}

# 	warn "Going to return undef";	
	
# 	return undef; # undef or hash
# }



1;