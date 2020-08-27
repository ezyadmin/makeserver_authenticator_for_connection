# !/usr/bin/perl

use strict;
use warnings;
use Carp;
# use Data::Dumper;

my $signature = <<EOF;
#######################################################
#       ____           ___      __        _     
#      / __/___ __ __ / _ | ___/ /__ _   (_)___ 
#     / _/ /_ // // // __ |/ _  //  ' \\ / // _ \\
#    /___/ /__/\\_, //_/ |_|\\_,_//_/_/_//_//_//_/
#             /___/               
######################################################
EOF
print $signature . "\n";

if ($> != 0) {
    print "\x1b[31mError: You must run this script by root permission, otherwise, you will not have privilege to properly install.\x1b[0m\n";
    exit;
}

if (defined $ARGV[0] && ($ARGV[0] eq 'deactivate' || $ARGV[0] eq '--deactivate')) {
  EzyAdminDeactivateAuth::init();
} else {
  EzyAdminActivateAuth::init();
}

exit;
#######################################################
#       ____           ___      __        _     
#      / __/___ __ __ / _ | ___/ /__ _   (_)___ 
#     / _/ /_ // // // __ |/ _  //  ' \\ / // _ \\
#    /___/ /__/\\_, //_/ |_|\\_,_//_/_/_//_//_//_/
#             /___/               
######################################################
package EzyAdminActivateAuth;
use strict;
use warnings;
use Fcntl ':mode';
# use Data::Dumper;
{
  sub init {
    if ($^O eq 'MSWin32') {
      EzyAdminActivateAuth::activate_on_windows();
    } else {
      EzyAdminActivateAuth::activate_on_linux();
    }
  }

  sub activate_on_linux {
    print "Please answer the following questions.\n";
    my ($authorize_user);
    my ($create_new_user) = 1; 
    do {
      # my $input_user = EzyAdminSystem::prompt("Do you want allow EzyAdmin remote access to this server with user (Create new if not exist):");
      # if (getpwnam($input_user)) {
      #   print "Found user \"$input_user\" in this server.\n";
      #   my $make_sure;
      #   do {
      #     $make_sure = EzyAdminSystem::prompt("You make sure allow EzyAdmin remote access to this server with user \"$input_user\" [y/n]:");
      #     chomp($make_sure);
      #     $make_sure = lc($make_sure);
      #   } while ($make_sure ne 'y' && $make_sure ne 'n');
      #   if ($make_sure eq 'n') {
      #     $authorize_user = '';
      #   } else {
      #     $authorize_user = $input_user;
      #     $create_new_user = 0;
      #   }
      # } else {
      #   $authorize_user = $input_user;
      # }
      my $input_user = '';
      my $default_user = EzyAdminSystem::prompt("Allow EzyAdmin access to this server as root using ezyadmin user? [y/n]");
      if ($default_user eq 'y') {
        $input_user = 'ezyadmin'
      } else {
        my $is_check_reserved = 0;
        do {
          $input_user = EzyAdminSystem::prompt("Please enter the user name to allow EzyAdmin access to this server as root (create new user if it doesn't exist):");
          # print "===>\$input_user=$input_user\n";
          if ($input_user && $input_user =~ /^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$/) {
            $is_check_reserved = EzyAdminFunction::validate_reserved_user($input_user);
            # print "===>\$is_check_reserved=$is_check_reserved\n";
            if (!$is_check_reserved) {
              EzyAdminFunction::print_error("User '$input_user' is a reserved username on EzyAdmin System")
            }
          } else {
            # print "===>verify user not pass : $input_user\n";
            EzyAdminFunction::print_error("User '$input_user' invalid.")
          }
        } while (!$is_check_reserved);
      }
      if (getpwnam($input_user)) {
        print "Found user \"$input_user\" in this server.\n";
        my $make_sure;
        do {
          $make_sure = EzyAdminSystem::prompt("You make sure allow EzyAdmin remote access to this server with user \"$input_user\" [y/n]:");
          chomp($make_sure);
          $make_sure = lc($make_sure);
        } while ($make_sure ne 'y' && $make_sure ne 'n');
        if ($make_sure eq 'n') {
          $authorize_user = '';
        } else {
          $authorize_user = $input_user;
          $create_new_user = 0;
        }
      } else {
        $authorize_user = $input_user;
      }
    } while ($authorize_user eq '');
    
    my $publickey;
    do {
      $publickey = EzyAdminSystem::prompt("Please input SSH public key (Loop up from EzyAdmin/Server onboarding):");
      if ($publickey !~ /^ssh-rsa / && $publickey !~ /^from=\"/) {
        print "Sorry, it's not SSH public key pattern, please input again.\n";
        $publickey = "";
      }
    } while ($publickey eq '');

    my $allow_ips = '';

    if ($publickey =~ /^from=\"(.*?)\"/) {
      $allow_ips = $1;
    }

    print "\n";
    print "Task Information.\n";
    print "OS Type: Linux\n";
    if ($create_new_user) {
      print "Create new user \"$authorize_user\" for remote access.\n";
    } else {
      print "Allow remote access with user \"$authorize_user\".\n";
    }
    print "Set authentcation to user \"$authorize_user\" with SSH public key.\n";
    print "Setup defaults sudoers for user \"$authorize_user\" with SSH public key.\n";
    if ($allow_ips ne "" && EzyAdminCSF::have_csf()) {
      print "Allow EzyAdmin IP address \"$allow_ips\" on csf firewall.\n";
    }
    
    print "\n";
    my ($confirm);
    $confirm = EzyAdminSystem::prompt("Press any key to continue or press \"x\" to exit.", 1);
    chomp($confirm);
    if (lc($confirm) eq 'x') {
      print "\n";
      exit;
    } else {
      print "Begin activate.\n";

      ## Setup user to access
      if ($create_new_user) {
        eval {
          my $shell_path = EzyAdminSystem::cmd_which('bash');
          EzyAdminSystem::execute("useradd $authorize_user -m -d /home/$authorize_user -s $shell_path -c 'EzyAdmin remote access account'");
          print "Create user \"$authorize_user\" has been successuly.\n";
        };
        if ($@) {
          print $@;
          exit;
        }
      } else {
        eval {
          my $su_path = EzyAdminSystem::cmd_which('su');
          my $wheel_id = EzyAdminSystem::call_backticks("cat /etc/group | grep --regex \"^wheel:.*\"");
          chomp($wheel_id);
          if ($wheel_id ne '') {
            EzyAdminSystem::execute("usermod -a -G $wheel_id $authorize_user");
            print "Append user \"$authorize_user\" to group \"wheel\".\n";
          }

          my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = lstat($su_path);
          my $otherExecute =  $mode & S_IXOTH;
          if ($otherExecute eq 0) {
            my $userGroup = getgrgid($gid);
            my $groupExecute = ($mode & S_IXGRP) >> 3;
            if ($userGroup ne 'root' && $groupExecute eq 1) {
              EzyAdminSystem::execute("usermod -a -G $userGroup $authorize_user");
              print "Append user \"$authorize_user\" to group \"$userGroup\" for execute command $su_path.\n";
            }
          }
        };
        if ($@) {
          print $@;
          exit;
        }
      }

      ## Setup authorized_keys file
        my $ssh_dir = "/home/$authorize_user/.ssh";
        my $authorized_keys_file = $ssh_dir . '/authorized_keys';
      eval {
        my $contents = $publickey;
        if (!-d $ssh_dir) {
          system("mkdir -p $ssh_dir");
        }
        EzyAdminFiles::put_content($authorized_keys_file, $contents, "a+");
        EzyAdminSystem::changemod('0700', $ssh_dir);
        EzyAdminSystem::changemod('0600', $authorized_keys_file);
        EzyAdminSystem::changeowner($authorize_user, $authorize_user, $ssh_dir);
        EzyAdminSystem::changeowner($authorize_user, $authorize_user, $authorized_keys_file);
        print "Append SSH public key to file $ssh_dir/authorized_keys\n";
      };
      if ($@) {
        print $@;
        exit;
      }
      
      ## Setup default sudoers
      eval {
        if (-f '/etc/sudoers') {
          EzyAdminSystem::execute("sed -i 's/^Defaults\\s*requiretty\\s*/# Defaults    requiretty\\n/g' /etc/sudoers");
        }
        my $alias = <<EOF;
Cmnd_Alias SHELLS= /bin/ksh, /bin/zsh, \\
  /bin/csh, /bin/tcsh, \\
  /usr/bin/login, /usr/sbin/nologin
EOF
        EzyAdminFiles::put_content('/etc/sudoers.d/SHELLS', $alias);
        my $contents = <<EOF;
$authorize_user ALL=(ALL) NOPASSWD:ALL, !SHELLS
EOF
        EzyAdminFiles::put_content('/etc/sudoers.d/' . $authorize_user, $contents);
        EzyAdminSystem::changemod('0440', '/etc/sudoers');
        EzyAdminSystem::changemod('0440', '/etc/sudoers.d/' . $authorize_user);
        EzyAdminSystem::changemod('0440', '/etc/sudoers.d/SHELLS');
        print "Append SSH public key to file $ssh_dir/authorized_keys\n";

      };
      if ($@) {
        print $@;
        exit;
      }
    }

    # Allow EzyAdmin on filewall (csf)
    eval {
      if ($allow_ips ne "" && EzyAdminCSF::have_csf()) {
        my @ipList = split(",", $allow_ips);
        EzyAdminCSF::allow_ips(@ipList);
        print "Allow EzyAdmin IPS in csf firewall.\n";
      }
    };
    if ($@) {
      print $@;
      exit;
    }

    my $ssh_port = EzyAdminVariable::ssh_port();

    my $contents = <<EOF;
user=$authorize_user
allow_ips=$allow_ips
ssh_key=$publickey
ssh_port=$ssh_port
EOF
    EzyAdminFiles::put_content("/etc/ezyadmin_activate.data", $contents);


    my $output .= <<EOF;

  Information for connection (server onboarding) 
  Authorize User: $authorize_user
  SSH Port: $ssh_port

Please go to EzyAdmin application and put this information to server onboarding step connection. 
EOF
    print $output;

  }

  sub activate_on_windows {
    print "OS Type: Windows\n";
    print "Under construction\n"; exit;
  }
}


package EzyAdminDeactivateAuth;
use strict;
use warnings;
use vars qw ($INSTANCE);
# use Data::Dumper;
{
  sub init {
    print "Under construction\n"; exit;
  }
}


package EzyAdminSystem;
use strict;
use warnings;
# use Data::Dumper;
{
  sub prompt {
    my $promptLable = shift;
    my $allowBlank = shift;
    my $promptValue = '';
    do {
      print $promptLable . " ";
      chomp($promptValue = <STDIN>);
    } while ($promptValue eq '' && defined $allowBlank && $allowBlank ne 1);
        
    return $promptValue;
  }

  sub cmd_which {
    my $cmd = shift;

    if ($cmd eq '' || $cmd =~ /\//) {
      return undef;
    }

    my $whichCmd = '';
    my $binpath = undef;
    my @binpathList = (
      '/bin',
      '/usr/bin',
      '/usr/local/bin',
      '/sbin',
      '/usr/sbin',
      '/usr/local/sbin'
    );

    foreach my $path(@binpathList) {
      if ( -x $path . '/' . 'which') {
        $whichCmd = $path . '/' . 'which';
        last;
      }
    }

    if ($whichCmd eq '') {
      return undef;
    }

    $binpath = EzyAdminSystem::call_backticks("$whichCmd $cmd");
    chomp ($binpath);
    $binpath =~s/\n|\r//gi;

    if ($binpath eq '') {
      foreach my $path(@binpathList) {
        if ( -x $path . '/' . $cmd) {
          $binpath = $path . '/' . $cmd;
          last;
        }
      }
    }

    if ($binpath eq '' || !-x $binpath) {
      return undef;
    }

    return $binpath;
  }

  sub call_backticks {
    my $cmd = shift;

    if (-f '.rvsBackticks') {
      system('rm -f .rvsBackticks');
    }

    my ($TestBackticks) = `echo 'EzyAdmin Test Backticks'`;
    my ($skipBackticks) = 0;

    if ($TestBackticks !~ /EzyAdmin Test Backticks/) {
      $skipBackticks = 1;
    }

    if ($skipBackticks eq 1) {
      system("$cmd > .rvsBackticks 2>&1");
    }

    my ($res);
    if (-f '.rvsBackticks') {
      $res = EzyAdminFiles::get_contents(".rvsBackticks");
      system('rm -f .rvsBackticks');
    } else {
      $res = `$cmd 2>&1`;
      chomp($res);
    }
    return $res;
  }

  sub execute {
    my ($command) = shift;
    system($command);
    return 1;
  }

  sub changemod {
    my ($mode, $source) = @_;
    my $res = 0;
    if (defined($mode) && -e $source) {
      $res = (chmod(oct($mode), $source)) ? 1 : "Cannot change mod to " . $mode;
    }
    return $res;
  }

  sub changeowner {
    my ($owner, $group, $dest) = @_;
    my $res = 1;
    if (defined($owner) && defined($group) && defined($dest) && -e $dest) {
      my $uid = getpwnam($owner);
      my $gid = getgrnam($group);
      $res = (chown($uid, $gid, $dest)) ? 1 : "Cannot change owner to " .  $owner . ":" . $group;
    }

    return $res;
  }

}

package EzyAdminCSF;
use strict;
use warnings;
{
  sub have_csf {
    my $path = EzyAdminSystem::cmd_which('csf');
    if (!$path) {
      return 0;
    } else {
      return 1;
    }
  }

  sub allow_ips {
    my @ips = @_;
    if (EzyAdminCSF::have_csf()) {
      my $csfBin = EzyAdminSystem::cmd_which('csf');
      foreach my $ip (@ips) {
        EzyAdminSystem::execute($csfBin . ' --add ' . $ip . ' EzyAdmin Server');
      }
      EzyAdminSystem::execute($csfBin. ' -r');
    }
  }

  sub delete_ips {
    my @ips = @_;
    if (EzyAdminCSF::have_csf()) {
      my $csfBin = EzyAdminSystem::cmd_which('csf');
      foreach my $ip (@ips) {
        EzyAdminSystem::execute($csfBin . ' --addrm ' . $ip);
      }
      EzyAdminSystem::execute($csfBin. ' -r');
    }
  }
}

package EzyAdminFiles;
use strict;
use warnings;
use Fcntl qw(:flock SEEK_END);
# use Data::Dumper;
{
  sub get_contents {
    my $filename = shift;
    my ($contents) = "";
    if (open(FILEHANDLE, $filename)) { 
      flock(FILEHANDLE, LOCK_EX);
      $contents = join("", <FILEHANDLE>);
      flock(FILEHANDLE, LOCK_UN);
      close(FILEHANDLE);
    }
    return $contents;
  }

  sub put_content {
    my ($filename, $data, $mode) = @_;
    $mode = (defined($mode) && $mode eq "a+") ? ">>" : '>';
    my $res = 0;

    if (defined($data)) {
      if (open(my $FILEHANDLE, $mode, $filename)) {
        flock($FILEHANDLE, LOCK_EX);
        print $FILEHANDLE $data;
        flock($FILEHANDLE, LOCK_UN);
        close($FILEHANDLE);
        $res = 1;
      }
    }
    return $res;
  }
}


package EzyAdminVariable;
use strict;
use warnings;
{
  sub is_integer {
    my $val = shift;
    return ($val =~ /^\d+$/) ? 1 : 0;
  }

  sub ssh_port {
    my $port = 22;
    my $output = EzyAdminSystem::call_backticks("netstat -tapen | grep /sshd | awk '{print \$4}'");
    my @aPorts = split(/\s+/, $output);
    foreach my $value (@aPorts) {
      my @aPort = split(/:+/, $value);
      if (defined $aPort[1] && EzyAdminVariable::is_integer($aPort[1])) {
        $port = $aPort[1];
        last;
      }
    }
    return $port;
  }

  sub os_release {
    my $version = 'unknown';
    if (-f '/etc/system-release') {
      $version = EzyAdminFiles::get_contents('/etc/system-release');
    } elsif (EzyAdminSystem::cmd_which('lsb_release')) {
      $version = EzyAdminSystem::call_backticks("lsb_release -d | awk '{print \$2,\$3,\$4}'");
    }
    chomp($version);
    return $version;
  }
}

package EzyAdminFunction;
use strict;
use warnings;
# use Data::Dumper;
{
  sub validate_reserved_user {
    my $username = shift;
    my $filename = 'data/reserved.txt';
    my $is_useable = 1;

    open(my $fh, '<:encoding(UTF-8)', $filename)
      or die "Could not open file '$filename' $!";
    
    while (defined(my $row = <$fh>) && $is_useable) {
      chomp $row;
      $row =~ s/^\s+|\s+$//g ;
      #print "==>$row\n";
      if ($row eq $username) {
        $is_useable = 0;
      }
    }
    return $is_useable;
  }
  sub print_error {
    my $err_message = shift;
    print "\x1b[31mError: $err_message\x1b[0m\n";
    return 0;
  }

}
1;
__END__ 
