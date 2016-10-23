### each function must return array

package Telegram::DynamicKeyboards;
# use Exporter::Auto;
use common::sense;


sub new {
  my $class = shift;
 	return bless {}, $class;  # Telegram::DynamicKeyboards exemplar will be hash
}

sub info_build_func {
	my $self = shift;
	return ['Google', 'Yandex', 'VK', 'Mail.ru'];	
}
	
sub dynamic1_build_func {
	my $self = shift;  # don't forget it if function is with variable
	my $text = shift;
	warn $text;
	if ($text eq 'morning') {
		return ['8:00', '9:00', '10:00', '11:00']
	}
	if ($text eq 'day') {
		return ['12:00', '13:00', '14:00', '15:00']
	}
	if ($text eq 'evening') {
		return ['16:00', '17:00', '18:00', '19:00']
		
	}
	if ($text eq 'night') {
		return ['20:00', '21:00', '22:00', '23:00']
	}
}



1;