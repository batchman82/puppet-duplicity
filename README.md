Puppet Duplicity
================

[![Build Status](https://travis-ci.org/batchman82/puppet-duplicity.png)](https://travis-ci.org/batchman82/puppet-duplicity)

Install Duplicity and quickly setup backup to Amazon S3

Important change
----------------
The parameter 'cloud' has been changed to 'provider' and config files have to be adapted accordingly.

Basic Usage
-----------
    node 'kellerautomat' {

      duplicity { 'a_backup':
        directory => '/home/soenke/',
        bucket    => 'test-backup-soenke',
        dest_id   => 'someid',
        dest_key  => 'somekey'
      }
    }

Preparing Backup
----------------

To prepare files for backup, you can use the ```pre_command``` parameter.
For example: do a mysqldump before running duplicity.

    duplicity { 'my_database':
      pre_command => 'mysqldump my_database > /my_backupdir/my_database.sql',
      directory   => '/my_backupdir',
      bucket      => 'test-backup',
      dest_id     => 'someid',
      dest_key    => 'somekey',
    }

Removing Old Backups
--------------------

To remove old backups after a successful backup, you can use the ```remove_older_than``` parameter.
For example: Remove backups older than 6 months:

    duplicity { 'my_backup':
      directory         => '/root/db-backup',
      bucket            => 'test-backup',
      dest_id           => 'someid',
      dest_key          => 'somekey',
      remove_older_than => '6M',
    }

Global Parameters
-----------------

Access ID and Key, Crypt-Pubkey and bucket name will be global in most cases. To avoid copy-and-paste
you can pass the global defaults once to duplicity::params before you include the duplicity class somewhere.

Example:

    class defaults {
      class { 'duplicity::params' :
        bucket            => 'test-backup-soenke',
        dest_id           => 'someid',
        dest_key          => 'somekey',
        remove_older_than => '6M',
      }
    }

    node 'kellerautomat' {

      include defaults

      duplicity { 'blubbi' :
        directory => '/home/soenke/projects/test-puppet',
      }
    }

Providers
---------
Currently the only supported providers are:
 * file  - Local file location
 * ssh   - Over SSH
 * s3    - Amazon S3 (default)
 * cf    - Rackspace Cloud

Local target
------------
Local backup, to for example an NFS mount.

Example:

    duplicity { 'my_local_backup':
      provider  => 'file',
      directory => '/root/db-backup',
      target    => '/mnt/a/mounted/place',
    }

SSH target
----------
Backup over SSH. This is using the scp protocol for now, 
maybe using rsync+ssh would be better?
Remember that SSH private key has to be owned by the user running ssh.
It must also be USER readable ONLY, otherwise SSH will reject it.

Example:

    duplicity { 'my_local_backup':
      provider  => 'ssh',
      directory => '/accessible/path',
      target    => 'remote.host.com//home/remoteuser/backup',
      dest_id   => 'remoteuser',
      dest_key  => '~/.ssh/id_rsa',
    }

This has the same result, note the '/' instead of '//':

    duplicity { 'my_local_backup':
      provider  => 'ssh',
      directory => '/accessible/path',
      target    => 'remote.host.com/backup',
      dest_id   => 'remoteuser',
      dest_key  => '~/.ssh/id_rsa',
    }

Different cron user
-------------------
This will be run as 'localuser' in cron, so make sure the directory to 
backup is accessible by that user:

    duplicity { 'my_local_backup':
      provider  => 'ssh',
      directory => '/accessible/path',
      target    => 'remote.host.com/backup',
      dest_id   => 'remoteuser',
      cron_user => 'localuser',
      dest_key  => '~/.ssh/id_rsa',
    }

Extended example
----------------
This is a more extended example, some parts are Ubuntu specific.

Example:

    class defaults {
      # Ubuntu specific, used to get Duplicity 0.6.21 from ppa
      package { 'python-software-properties': ensure => installed }
      exec { '/usr/bin/add-apt-repository -y ppa:duplicity-team/ppa':
        creates => "/etc/apt/sources.list.d/duplicity-team-ppa-${::lsbdistcodename}.list",
        require => Package[ 'python-software-properties' ]
      }
      exec { "duplicity-team-update":
        command     => "/usr/bin/apt-get update",
        require     => Exec[ '/usr/bin/add-apt-repository -y ppa:duplicity-team/ppa' ],
        refreshonly => true,
      }
      Package <| title == 'duplicity' |> { 
        ensure  => '0.6.21-0ubuntu0ppa21~precise1',
        require => Exec[ 'duplicity-team-update' ],
      }
      
      # Values with defaults does not need to be set
      class { 'duplicity::params' :
        bucket             => 'test-backup-soenke',
        dest_id            => 'someid',
        dest_key           => 'somekey',
        remove_older_than  => '6M',  # default = undef
        full_if_older_than => '15D', # default = '30D'
        provider           => 'cf',  # default = 's3'
        hour               => 1,     # default = 0
        minute             => 5,     # default = 0
        job_spool          => '/var/spool/duplicity'  # default = '/var/spool/duplicity'
        require            => Package[ 'duplicity' ], # Not really needed, but I prefer being explicit
      }
    }

    node 'kellerautomat' {
     
      include defaults
      
      duplicity { 'blubbi' :
        directory => '/home/soenke/projects/test-puppet',
        hour      => 3, # Overriding default again
        minute    => 7, # Overriding default again
      }
      
      # To remove the cron job, uncomment this:
      #Cron <| title == 'blubbi' |> { ensure => absent }
    }

Crypted Backups
---------------

In order to save crypted backups this module is able to make use of pubkey encryption.
This means you specify a pubkey and restores are only possible with the correspondending
private key. This ensures no secret credentials fly around on the machines. Incremental backups
work as long as the metadata cache on the node is up to date. Duplicity will force a full backup
otherwise because it cannot decrypt anything it downloads from the bucket.

Check https://answers.launchpad.net/duplicity/+question/107216 for more information.

Install duplicity without a backup job
--------------------------------------

If you want to only install the packages, include duplicity:packages

Restore
-------

Nobody wants backup, everybode wants restore. 
