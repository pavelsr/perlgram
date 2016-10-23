# Almost all methods has at least one argument = chat_id

package Telegram::Sessions;
use common::sense;

sub new {
    my $class = shift;
    my $sess_obj = {};
    $sess_obj->{session} = {};
    bless $sess_obj, $class;
    return $sess_obj;
}

# getter
sub all {
	my ($self, $chat_id) = @_;
	if ($chat_id) {
		if (defined $self->{session}{$chat_id}) {
			return $self->{session}{$chat_id};
		} else {
			return undef;
		}
	} else {
		return $self->{session};
	}
}

# Get all messages of session with particular chat ID and $key
sub all_keys_arr {
	my ($self, $chat_id, $key) = @_;
	my @msgs;
	for (@{$self->{session}{$chat_id}}) {
		push @msgs, $_->{$key};
	}
	return \@msgs;
}

sub start {
    my ($self, $chat_id) = @_;
   	$self->{session}{$chat_id} = [];
}

# Delete session
sub del {
    my ($self, $chat_id) = @_;
    delete $self->{session}{$chat_id};
}

# technical method for testing
sub _set {
   my ($self, $chat_id, $array) = @_;
   $self->{session}{$chat_id} = $array;
}

# sub update {
# 	my ($self, $chat_id, $update, $add_data) = @_;
# 		my @active_sess_uids = keys %{$self->{session}};
# 		if ((grep  { $chat_id eq $_ } @active_sess_uids)) {
# 			my $hash;
# 			$hash->{update} = $update;
# 			if ($add_data) {
# 				$hash->{add_data} = $add_data;
# 			}
# 			push @{$self->{session}->{$chat_id}}, $hash;
# 		}
# 	return $self->{session};
# }

sub update {
	my ($self, $chat_id, $hash_with_data) = @_;
	my @active_sess_uids = keys %{$self->{session}};

	if ((grep  { $chat_id eq $_ } @active_sess_uids)) {
		push @{$self->{session}->{$chat_id}}, $hash_with_data;
	}

	return $self->{session}->{$chat_id};
}


sub last {
	my ($self, $chat_id) = @_;
	if ($self->{session}{$chat_id}) { 
		my @sess_for_chat = @{$self->{session}{$chat_id}}; 
		return $sess_for_chat[$#sess_for_chat];   # last elenemt
	} else {
		return undef;
	}
}


# Return hash that combines two properies of session
# $params = { name_of_hash_key, first_property, second_property }

sub combine_properties {
	my ($self, $chat_id, $params) = @_;
	my $kv = {};
	for (@{$self->{session}{$chat_id}}) {
		$kv->{$_->{$params->{first_property}}} = $_->{$params->{second_property}};
	}
	my $returned_hash;
	$returned_hash->{$params->{name_of_hash_key}} = $kv;
	return $returned_hash;
}


# Return hash that combines two properies of session
# screen from CURRENT element and callback text from NEXT

sub combine_properties_retrospective {
	my ($self, $chat_id, $params) = @_;
	my $kv = {};
	my @sess = @{$self->{session}{$chat_id}};

	for my $i (0 .. $#sess-1) {
		my $key = $sess[$i]->{$params->{first_property}};
		my $value = $sess[$i+1]->{$params->{second_property}};
		$kv->{$key} = $value;
	}

	my $returned_hash;
	$returned_hash->{$params->{name_of_hash_key}} = $kv;
	return $returned_hash;
}

## specific usage of combine_properties_retrospective()
sub get_replies_hash {
	my ($self, $chat_id) = @_;
	my $params = { 
		name_of_hash_key => 'replies', 
		first_property => 'screen',
		second_property => 'callback_text'
	};
	my $res = $self->combine_properties_retrospective($chat_id,$params);
	return $res;
}

1;