# Duplicity::Job TODO: Write a good definition
define duplicity::job(
  $spoolfile,
  $ensure             = 'present',
  $directory          = undef,
  $bucket             = undef,
  $target             = undef,
  $dest_id            = undef,
  $dest_key           = undef,
  $folder             = undef,
  $provider           = undef,
  $pubkey_id          = undef,
  $full_if_older_than = undef,
  $pre_command        = undef,
  $remove_older_than  = undef,
  $default_exit_code  = undef,
  $cron_user          = undef,
) {

  include duplicity::params
  include duplicity::packages

  $_bucket = $bucket ? {
    undef   => $duplicity::params::bucket,
    default => $bucket
  }

  $_target = $target ? {
    undef   => $duplicity::params::target,
    default => $target
  }

  $_dest_id = $dest_id ? {
    undef   => $duplicity::params::dest_id,
    default => $dest_id
  }

  $_dest_key = $dest_key ? {
    undef   => $duplicity::params::dest_key,
    default => $dest_key
  }

  $_folder = $folder ? {
    undef   => $duplicity::params::folder,
    default => $folder
  }

  $_provider = $provider ? {
    undef   => $duplicity::params::provider,
    default => $provider
  }

  $_pubkey_id = $pubkey_id ? {
    undef   => $duplicity::params::pubkey_id,
    default => $pubkey_id
  }

  $_hour = $::hour ? {
    undef   => $duplicity::params::hour,
    default => $::hour
  }

  $_minute = $::minute ? {
    undef   => $duplicity::params::minute,
    default => $::minute
  }

  $_full_if_older_than = $full_if_older_than ? {
    undef   => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $_pre_command = $pre_command ? {
    undef   => '',
    default => "${pre_command} && "
  }

  $_encryption = $_pubkey_id ? {
    undef   => '--no-encryption',
    default => "--encrypt-key ${_pubkey_id}"
  }

  $_remove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  if !($_provider in [ 'file', 'ssh', 's3', 'cf' ]) {
    fail('$provider required and supports:
file  - Local file location
ssh   - Over SSH
s3    - Amazon S3
cf    - Rackspace Cloud Files')
  }

  case $ensure {
    present : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }
      
      if ($_provider in [ 'file', 'ssh' ]) {
        if !$_bucket {
          fail('You need to define a target name!')
        }
      }
      
      if ($_provider in [ 's3', 'cf' ]) {
        if !$_bucket {
          fail('You need to define a container/bucket name!')
        }
      }
      if ($_provider in [ 'ssh', 's3', 'cf' ]) {
        if (!$_dest_id or !$_dest_key) {
          fail('You need to set all of your key variables: dest_id, dest_key')
        }
      }
    }

    absent : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }
  
  $_emptyhash = { }
  $_cfhash = {  'CLOUDFILES_USERNAME'    => $_dest_id,
                'CLOUDFILES_APIKEY'      => $_dest_key, }
  $_awshash = { 'AWS_ACCESS_KEY_ID'      => $_dest_id,
                'AWS_SECRET_ACCESS_KEY'  => $_dest_key, }
  
  $_extra_param = $_provider ? {
    'file' => '',
    'ssh'  => "--ssh-options='-i ${_dest_key}'",
    'cf'   => '',
    's3'   => '--s3-use-new-style',
  }
  
  $_environment = $_provider ? {
    'file' => $_emptyhash,
    'ssh'  => $_emptyhash,
    'cf'   => $_cfhash,
    's3'   => $_awshash,
  }

  $_target_url = $_provider ? {
    'file' => "'file://${_target}'",
    'ssh'  => "'scp://${_dest_id}@${_target}'",
    'cf'   => "'cf+http://${_bucket}'",
    's3'   => "'s3+http://${_bucket}/${_folder}/${name}/'"
  }

  $_remove_older_than_command = $_remove_older_than ? {
    undef   => '',
    default => " && duplicity remove-older-than ${_remove_older_than} ${_extra_param} ${_encryption} --force ${_target_url}"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template('duplicity/file-backup.sh.erb'),
    owner   => $cron_user,
    mode    => '0700',
  }

  if $_pubkey_id {
    exec { 'duplicity-pgp':
      command => "gpg --keyserver subkeys.pgp.net --recv-keys ${_pubkey_id}",
      path    => '/usr/bin:/usr/sbin:/bin',
      unless  => "gpg --list-key ${_pubkey_id}"
    }
  }
}
