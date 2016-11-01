# Name

perlgram - Perl framework (set of Perl modules) for easily builbing simple Telegram text bots

Main class is Telegram::Wizard

# Synopsis

```
my $api = WWW::Telegram::BotAPI->new (
    token => $config->{token}
);
my $config = Config::JSON->new('examples/screens.json');

my $w = Telegram::Wizard->new({
	screens_arrayref => $config->{screens},
	dyn_kbs_class => 'Telegram::DynamicKeyboards',
	keyboard_type => 'regular',
	max_keys_per_row => 2,
	debug => 1
});

...

# process of $Update objects

my $res = $w->process($update);
$api->sendMessage($res);

```

Easy. Peasy. Japanesey

Fore more info check out simulator.pl code

To install all dependencies run ``installdeps.sh`` script

# Description

## Core features

* state machine in json file (allow to create a simple bots for even a housewife)
* dymanically generated screens by any third-party Perl module
* independent and prev msg dependent screens
* data validation
* support of custom serialization functions

## Core concepts 

Screen = welcome text + reply markup

Dynamic screen = screen that depends on previous user input


## Known issues

* No validation for last screen


## For developers

### Typical errors


```Can't call method "build_keyboard_array" on unblessed reference ``` or
```Can't call method "is_static" on an undefined value ```

Check that all class functions are called as $self->func($param)

### State diagram of Telegram::Wizard

![state diagram](http://i.imgur.com/MNWI4MX.png)

### Telegram API documentation

### Useful links

https://metacpan.org/pod/perlmodstyle - Perl module style guide

https://metacpan.org/pod/perlnewmod - preparing a new module for distribution


### Useful classes

Class::Inspector - https://metacpan.org/pod/Class::Inspector

Class::Sniff - https://metacpan.org/pod/Class::Sniff

ExtUtils::MakeMaker - https://metacpan.org/pod/ExtUtils::MakeMaker

Module::Build - https://metacpan.org/pod/Module::Build