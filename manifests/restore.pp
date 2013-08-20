# Duplicity::Restore TODO: Write a good definition
define duplicity::restore(
  $ensure             = 'present',
  $directory          = undef,
  $bucket             = undef,
  $source             = undef,
  $target             = undef,
  $dest_id            = undef,
  $dest_key           = undef,
  $folder             = undef,
  $provider           = undef,
  $privkey_id         = undef,
  $default_exit_code  = undef,
) {

  include duplicity::params
  include duplicity::packages

  $_bucket = $bucket ? {
    undef   => $duplicity::params::bucket,
    default => $bucket
  }

  $_source = $source ? {
    undef   => $duplicity::params::source,
    default => $source
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

  $_privkey_id = $privkey_id ? {
    undef   => $duplicity::params::privkey_id,
    default => $privkey_id
  }

  $_hour = $::hour ? {
    undef   => $duplicity::params::hour,
    default => $::hour
  }

  $_minute = $::minute ? {
    undef   => $duplicity::params::minute,
    default => $::minute
  }

  $_encryption = $_privkey_id ? {
    undef   => '--no-encryption',
    default => "--encrypt-key ${_privkey_id}"
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
  
  $_emptyenvir = [ ]
  $_cfenvir = [ "CLOUDFILES_USERNAME=${_dest_id}",
                     "CLOUDFILES_APIKEY=${_dest_key}", ]
  $_awenvir = [ "AWS_ACCESS_KEY_ID=${_dest_id}",
                "AWS_SECRET_ACCESS_KEY=${_dest_key}", ]
  
  $_extra_param = $_provider ? {
    'file' => '',
    'ssh'  => "--ssh-options='-i ${_dest_key}'",
    'cf'   => '',
    's3'   => '--s3-use-new-style',
  }
  
  $_environment = $_provider ? {
    'file' => $_emptyenvir,
    'ssh'  => $_emptyenvir,
    'cf'   => $_cfenvir,
    's3'   => $_awenvir,
  }

  $_source_url = $_provider ? {
    'file' => "'file://${_source}'",
    'ssh'  => "'scp://${_dest_id}@${_source}'",
    'cf'   => "'cf+http://${_bucket}'",
    's3'   => "'s3+http://${_bucket}/${_folder}/${name}/'"
  }
  
  exec { "${name}":
    command     => "duplicity --file-to-restore ${directory} ${_extra_param} ${_encryption} ${_source_url} ${target}",
    path        => '/usr/bin:/usr/sbin:/bin',
    environment => $_environment,
    creates     => $target,
    require     => Package[ 'duplicity' ],
  }
  
  $_remove_older_than_command = $_remove_older_than ? {
    undef   => '',
    default => " && duplicity remove-older-than ${_remove_older_than} ${_extra_param} ${_encryption} --force ${_target_url}"
  }

}
