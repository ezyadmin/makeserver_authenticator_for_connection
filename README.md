# Make server authenticator for connect to EzyAdmin

วิธีการสร้าง User เพื่อใช้ใน connection server เข้าสู่ระบบ EzyAdmin

## ใช้ script ช่วยในการติดตั้ง

perl ./ezy_authentication.pl

## ติดตั้งเอง

สามารถติดตั้งเองโดยทำตามขั้นตอนต่อไปนี้

### Linux

- สร้าง user เพื่อใช้ในการ authenticator

  - Create user
    useradd -m -d /home/{{user}} -s -c "EzyAdmin Account" {{user}}
  - Find ID of user group wheel
    id -g wheel
  - Add user to group wheel
    usermod -a -G {{group_wheel_id}} {{user}}
  - ค้นหา group execute id สำหรับ /bin/su
    perl -e 'use strict; use Fcntl ":mode"; my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = lstat("/bin/su"); my $otherExecute = $mode & S_IXOTH; if ($otherExecute) { my $userGroup = getgrgid($gid); my $groupExecute = ($mode & S_IXGRP) >> 3; if ($userGroup ne "root" && $groupExecute eq 1) { print "\$userGroup\n";} else { print "NULL\n";}} else { print "NULL\n";}'
  - ถ้าหากค่า group execute id สำหรับ /bin/su ไม่ได้มา ไม่มีค่าเป็น NULL ให้ทำการ Add user to group xxx ด้วย
    usermod -a -G {{su_execute_group_id}} {{user}}

- Add public key to file authorized_keys for user

  - สร้างโฟเดอร์ /home/{{user}}/.ssh
    mkdir -p /home/{{user}}/.ssh
  - สร้างไฟล์ /home/{{user}}/.ssh/authorized_keys
    touch /home/{{user}}/.ssh/authorized_keys
  - บันทึกค่า SSH public key ที่ได้จาก EzyAdmin/Server onboarding ลงในไฟย์ /home/{{user}}/.ssh/authorized_keys
  - Setup permissions and owner
    chmod 700 /home/{{user}}/.ssh
    chmod 0600 /home/{{user}}/.ssh/authorized_keys
    chwon {{user}}:{{user}} /home/{{user}}/.ssh
    chwon {{user}}:{{user}} /home/{{user}}/.ssh/authorized_keys

- Setup defaults sudoers
  - Comment Line: Defaults requiretty in file /etc/sudoers
    sed -i "s/^Defaults\s*requiretty\s*/# Defaults requiretty\n/g" /etc/sudoers
  - Edit "Cmnd_Alias SHELLS" in file /etc/sudoers.d/SHELLS
    Cmnd_Alias SHELLS= /bin/ksh, /bin/zsh, /bin/csh, /bin/tcsh, /usr/bin/login, /usr/sbin/nologin
  - Edit in file /etc/sudoers.d/{{user}}
    {{user}} ALL=(ALL) NOPASSWD:ALL, !SHELLS
  - Setup permissions
    chmod 440 /etc/sudoers.d/SHELLS
    chmod 440 /etc/sudoers.d/{{user}}
- Allow EzyAdmin on filewall (csf)
  - Add EzyAdmin IP (Lookup in EzyAdmin App)
    csf --add {{EzyAdmin IP}} "EzyAdmin Ansible Server"
  - Restart csf filewall
    csf -r

### Windows
