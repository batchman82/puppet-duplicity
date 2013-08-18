# Duplicity TODO: Write a good definition
define duplicity(
  $ensure             = 'present',
  $directory          = undef,
  $bucket             = undef,
  $dest_id            = undef,
  $dest_key           = undef,
  $folder             = undef,
  $provider           = undef,
  $pubkey_id          = undef,
  $hour               = undef,
  $minute             = undef,
  $full_if_older_than = undef,
  $pre_command        = undef,
  $remove_older_than  = undef,
) {

  include duplicity::params
  include duplicity::packages

  $spoolfile = "${duplicity::params::job_spool}/${name}.sh"

  duplicity::job { $name :
    ensure             => $ensure,
    spoolfile          => $spoolfile,
    directory          => $directory,
    bucket             => $bucket,
    dest_id            => $dest_id,
    dest_key           => $dest_key,
    folder             => $folder,
    provider           => $provider,
    pubkey_id          => $pubkey_id,
    full_if_older_than => $full_if_older_than,
    pre_command        => $pre_command,
    remove_older_than  => $remove_older_than,
  }

  $_hour = $hour ? {
    undef   => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef   => $duplicity::params::minute,
    default => $minute
  }

  cron { $name :
    ensure  => $ensure,
    command => $spoolfile,
    user    => 'root',
    minute  => $_minute,
    hour    => $_hour,
  }

  File[$spoolfile]->Cron[$name]
}
