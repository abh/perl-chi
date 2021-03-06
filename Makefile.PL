use inc::Module::Install;

name 'CHI';
abstract 'Unified cache interface';
all_from 'lib/CHI.pm';
author 'Jonathan Swartz <swartz@pobox.com>';

perl_version '5.006';

build_requires 'Date::Parse'                 => 0;
build_requires 'Log::Any::Adapter::Dispatch' => '0.05';
build_requires 'Test::Builder'               => 0;
build_requires 'Test::Class'                 => 0;
build_requires 'Test::Deep'                  => 0;
build_requires 'Test::Exception'             => 0;
build_requires 'Test::Log::Dispatch'         => 0;
build_requires 'Test::More'                  => 0;
build_requires 'Test::Warn'                  => 0;

requires 'Carp::Assert'              => '0.20';
requires 'Data::UUID'                => 0;
requires 'Digest::JHash'             => 0;
requires 'Digest::MD5'               => 0;
requires 'File::Spec'                => '0.80';
requires 'Hash::MoreUtils'           => 0;
requires 'JSON'                      => 0;
requires 'List::MoreUtils'           => '0.13';
requires 'Log::Any'                  => '0.06';
requires 'Module::Load::Conditional' => 0;
requires 'Moose'                     => '0.66';
requires 'Storable'                  => 0;
requires 'Task::Weaken'              => 0;
requires 'Time::Duration'            => '1.06';
requires 'Time::Duration::Parse'     => '0.03';

no_index directory => 'lib/CHI/t';
no_index directory => 'lib/CHI/Test';
no_index package => 'CHI::Constants';
no_index package => 'CHI::Serializer::Storable';
no_index package => 'CHI::Test';
no_index package => 'CHI::Types';
no_index package => 'CHI::Util';

extra_tests;

license 'perl';

auto_install;

WriteAll;
