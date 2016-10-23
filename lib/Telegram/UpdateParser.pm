## Module for parsing Telegram Update object
## Resolve issue of adding bot in a group chat

package Telegram::UpdateParser;
use common::sense;

use Exporter qw(import);
our @EXPORT_OK = qw(get_text get_chat_id);

sub parse {
	my $update = shift;
	if ($update->{message}{text}) {
		return { data => $update->{message}{text}, chat_id => $update->{message}{chat}{id} };
	}
	if ($update->{callback_query}{data}) {
		return { data => $update->{callback_query}{data}, chat_id => $update->{callback_query}{message}{chat}{id} };
	}
}


sub get_text {
	my $update = shift;
	parse($update)->{data};
}

sub get_chat_id {
	my $update = shift;
	parse($update)->{chat_id};
}

1;