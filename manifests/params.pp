# Duplicity::Params TODO: Write a good definition
class duplicity::params(
  $bucket             = undef,
  $target             = undef,
  $dest_id            = undef,
  $dest_key           = undef,
  $provider           = $duplicity::defaults::provider,
  $pubkey_id          = undef,
  $hour               = $duplicity::defaults::hour,
  $minute             = $duplicity::defaults::minute,
  $full_if_older_than = $duplicity::defaults::full_if_older_than,
  $remove_older_than  = undef,
  $cron_user          = $duplicity::defaults::cron_user,
  $job_spool          = $duplicity::defaults::job_spool
) inherits duplicity::defaults {

  file { $job_spool :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  File[$job_spool] -> Duplicity::Job <| |>
}
