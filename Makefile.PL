use inc::Module::Install;

perl_version '5.8.1';
name 'Algorithm-RangeCoder';

all_from 'lib/Algorithm/RangeCoder.pm';

requires 'perl' => '5.8.1';
requires 'Data::Integer';
requires 'Class::Accessor::Lvalue';
requires 'POSIX';

auto_install;
WriteAll;
