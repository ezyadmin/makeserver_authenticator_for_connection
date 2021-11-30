# Make server authenticator for connect to EzyAdmin

How to make server authenticator for connect to EzyAdmin. 

## For Linux

## Install Dependencies

- Perl

```bash
yum install -y perl
```

## Script Installer (Recommended)

```bash
mkdir -p /usr/local/ezyadmin
cd /usr/local/ezyadmin/
wget https://github.com/ezyadmin/makeserver_authenticator_for_connection/archive/latest.tar.gz -O makeserver_authenticator_for_connection.tar.gz
tar -zxf makeserver_authenticator_for_connection.tar.gz
cd makeserver_authenticator_for_connection-latest
perl ./ezy_authentication.pl
```

You need to fill out something.

## Install yourself

- Create user for authenticator
- Create user via command

```bash
    useradd -m -d /home/{{user}} -s -c "EzyAdmin Account" {{user}}
```

- Find ID of user group wheel

```bash
    id -g wheel
```

- Add user to group wheel

```bash
    usermod -a -G {{group_wheel_id}} {{user}}
```

- Find group execute id for /bin/su

```bash
    perl -e 'use strict; use Fcntl ":mode"; my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = lstat("/bin/su"); my $otherExecute = $mode & S_IXOTH; if ($otherExecute) { my $userGroup = getgrgid($gid); my $groupExecute = ($mode & S_IXGRP) >> 3; if ($userGroup ne "root" && $groupExecute eq 1) { print "\$userGroup\n";} else { print "NULL\n";}} else { print "NULL\n";}'
```

- If not get the value of group execute id for /bin/su or the value is not "NULL" , add user to group "xxx".

```bash
    usermod -a -G {{su_execute_group_id}} {{user}}
```

- Add public key to authorized_keys file  for user
-Create folder '.ssh' in path /home/{{user}}

```bash
    mkdir -p /home/{{user}}/.ssh
```

- Create  authorized_keys file in path /home/{{user}}/.ssh/

```bash
    touch /home/{{user}}/.ssh/authorized_keys
```

- Copy public key that get from EzyAdmin/Server onboarding and then fill out in /home/{{user}}/.ssh/authorized_keys then save.
- Set permissions and owner of folder .ssh and authorized_keys file.

```bash
    chmod 700 /home/{{user}}/.ssh
    chmod 0600 /home/{{user}}/.ssh/authorized_keys
    chwon {{user}}:{{user}} /home/{{user}}/.ssh
    chwon {{user}}:{{user}} /home/{{user}}/.ssh/authorized_keys
```

- Set defaults sudoers
- Comment Line: Defaults require tty in file /etc/sudoers

```bash
    sed -i "s/^Defaults\s*requiretty\s*/# Defaults requiretty\n/g" /etc/sudoers
```

- Edit "Cmnd_Alias SHELLS" in file /etc/sudoers.d/SHELLS

```bash
    Cmnd_Alias SHELLS= /bin/ksh, /bin/zsh, /bin/csh, /bin/tcsh, /usr/bin/login, /usr/sbin/nologin
```

- Edit in file /etc/sudoers.d/{{user}}

```bash
    {{user}} ALL=(ALL) NOPASSWD:ALL, !SHELLS
```

- Set permissions

```bash
    chmod 440 /etc/sudoers.d/SHELLS
    chmod 440 /etc/sudoers.d/{{user}}
```

- Allow EzyAdmin on filewall (csf)
- Add EzyAdmin IP (Lookup in EzyAdmin App)

```bash
    csf --add {{EzyAdmin IP}} "EzyAdmin Ansible Server"
```

- Restart csf filewall

```bash
    csf -r
```

- Look up SSH port

```bash
netstat -tapen | grep /sshd | awk '{print $4}'
```

## For Ubuntu 

```bash
 apt-get install perl -y
```
## Script Installer (Recommended)
```bash

mkdir -p /usr/local/ezyadmin
cd /usr/local/ezyadmin/
wget https://github.com/ezyadmin/makeserver_authenticator_for_connection/archive/latest.tar.gz -O makeserver_authenticator_for_connection.tar.gz
tar -zxf makeserver_authenticator_for_connection.tar.gz
cd makeserver_authenticator_for_connection-latest
perl ./ezy_authentication.pl
```
You need to fill out something.

## Install yourself
- adduser

```/bin/bash 
useradd -s /bin/bash  -d /home/{{user}} -m -c "EzyAdmin Account" {{user}}
```

- Add public key to authorized_keys file  for user
-Create folder '.ssh' in path /home/{{user}}

```bash
    mkdir -p /home/{{user}}/.ssh
```

- Create  authorized_keys file in path /home/{{user}}/.ssh/

```bash
    touch /home/{{user}}/.ssh/authorized_keys
```

- Copy public key that get from EzyAdmin/Server onboarding and then fill out in /home/{{user}}/.ssh/authorized_keys then save.  


- Set permissions and owner of folder .ssh and authorized_keys file.

```bash
    chmod 700 /home/{{user}}/.ssh
    chmod 0600 /home/{{user}}/.ssh/authorized_keys
    chwon {{user}}:{{user}} /home/{{user}}/.ssh
    chwon {{user}}:{{user}} /home/{{user}}/.ssh/authorized_keys
```

- Set defaults sudoers
- Comment Line: Defaults require tty in file /etc/sudoers

```bash
    sed -i "s/^Defaults\s*requiretty\s*/# Defaults requiretty\n/g" /etc/sudoers
```

- Edit "Cmnd_Alias SHELLS" in file /etc/sudoers.d/SHELLS

```bash
    Cmnd_Alias SHELLS= /bin/ksh, /bin/zsh, /bin/csh, /bin/tcsh, /usr/bin/login, /usr/sbin/nologin
```

- Edit in file /etc/sudoers.d/{{user}}

```bash
    {{user}} ALL=(ALL) NOPASSWD:ALL, !SHELLS
```

- Set permissions

```bash
    chmod 440 /etc/sudoers.d/SHELLS
    chmod 440 /etc/sudoers.d/{{user}}
```

- Allow EzyAdmin on filewall (csf)
- Add EzyAdmin IP (Lookup in EzyAdmin App)

```bash
    csf --add {{EzyAdmin IP}} "EzyAdmin Ansible Server"
```

- Restart csf filewall

```bash
    csf -r
```

- Look up SSH port

```bash
netstat -tapen | grep /sshd | awk '{print $4}'
```



### Windows

## การติดตั้งโฮสต์เพื่อเชื่อมต่อระบบสำหรับ Windows Server

### ก่อนจะติดตั้ง Tools ต่างๆ ให้สร้าง User สำหรับใช้งาน Ansible ก่อน

 สร้าง User ชื่อ Ansible โดยกำหนดสิทธิ์ให้เป็น Administrator เพื่อทำการเชื่อมต่อกับ Ansible

 1. เข้าไปที่ Control Panel >> User Accounts >> User Accounts >> Manage Accounts >> **_Add a user account_**
 2. ใส่ชื่อ User : Ansible และ Password โดยมีเงื่อนไขประกอบด้วย ตัวอักษรภาษาอังกฤษพิมพ์ใหญ่ ,เล็ก ,อักขระ ,ตัวเลข ผสมอยู่อย่างน้อย 1 ตัว
 3. ที่หน้า Manage Accounts ให้ทำการเปลี่ยน Type User : Ansible เป็น Administrator เลือก User Ansible >> Change the account type >> Administrator >> Click **_Change Account Type_**

เพียงเท่านี้ก็มี User สำหรับใช้งาน Ansible แล้ว

----
ต่อไปจะเป็นขั้นตอนการติดตั้ง Tools ต่างๆ เพื่อที่จะใช้งานกับระบบ

 เริ่มต้นโดย Remote Desktop ด้วย User : **_Administrator_**

### Step 1. Install perl command

- Download and setup perl Click [Download](http://strawberryperl.com) **(Recommended version)**

----
### Step 2. Install CPAN module with command line

- Run Command >> **cpan Win32 Net::Domain User Win32::Service** in App : Perl (command line) installed step 1

----
### Step 3. Setup && Config WinRM
#### 3.1 : Setup WinRM, use this script, run the following in PowerShell:

```powershell
$url = "https://netwayws.com/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file
```

#### 3.2 : Enable basic authentication in PowerShell

```powershell
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```
#### 3.3 : Install SSL WinRm

1. Create Cert Run command in **Powershell**

  ```powershell
  $Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName **YOUR IPServer** 
  ```

2. Export Cert

* Start >> run >> certlm.msc >> Personal >> Certificates >> คลิ๊กขวา IPServer >> All Tasks >> Export

![export](/images/export.png)

3. Create Transport HTTPS Run command in **Powershell**

```powershell
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force 
```

4. Create Port 5986 บน Firewall Run command in **Powershell**

```powershell
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP
```

5. Enable Https Listener Run command in **Powershell**

```powershell
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true 
```

6. Check listener port Run command in **Powershell**

```powershell
dir wsman:\localhost\listener
```

![listener](/images/listener.png)

7. Import Certificate 

   * Start >> run >> certlm.msc >> Trusted Root Certification Authorities  >> Certificates >> คลิ๊กขวา >> All Tasks >> Import ( ไฟล์ที่เรา Export ไว้ในข้อ 2) 

![listener](/images/import.png)

8. Run command test connection in **Powershell**

```powershell
winrs -r:https://##IPServer##:5986/wsman -u:##Username## -p:##Password## -ssl ipconfig
```

Example & Output
```powershell
> PS D:\Download> winrs -r:https://192.168.0.10:5986/wsman -> u:administrator -p:0123456789 -ssl ipconfig 

  Windows IP Configuration 
  Ethernet adapter Ethernet: 
    Connection-specific DNS Suffix  . : 
    IPv4 Address. . . . . . . . . . . : 192.168.0.10
    Subnet Mask . . . . . . . . . . . : 255.255.255.0 
    Default Gateway . . . . . . . . . : 192.168.0.1 
  Tunnel adapter 6TO4 Adapter: 
     Connection-specific DNS Suffix  . : 
    IPv6 Address. . . . . . . . . . . :2001:db8:a1b2:12::2
    Default Gateway . . . . . . . . . : 2001:db8:a1b2:12::1 
    Media State . . . . . . . . . . . : Media disconnected 
  Connection-specific DNS Suffix  . : 
```
#### 3.4 : Test connection

**Test out HTTP**

```powershell
winrs -r:http://##Server##:5985/wsman -u:##Username## -p:##Password## ipconfig
```
**Test out HTTPS (will fail if the cert is not verifiable)**

```powershell
winrs -r:https://##Server##:5986/wsman -u:##Username## -p:##Password## -ssl ipconfig
```

----
<!-- ### Step 4. Download ezyadmin activate server script

- Download file ezyactivate.pl [Click Right and Save link as](https://raw.githubusercontent.com/ezyadmin/makeserver_authenticator_for_connection/master/ezy_authentication.pl) and Run >> perl ezy_authentication.pl in **Powershell**

### Step 5. สคริปจะถาม Ansible URL, และ Secret Key ในการติดตั้ง ให้นำข้อมูล Ansible Server ของ custommer ไปกรอก

```text
Ansible URL : http://203.78.103.160
Secret Key : a227da47cfb7d6975d8055675a43ac3ca473830a870577a16f20ed741b402e186d0a719e0be48add
```

### Step 6. เมื่อทำการติดตั้งเพื่อเชื่อมต่อระบบเสร็จ ให้ไปยืนยันการเชื่อมต่อระบบที่ Admin Server List

### Step 7. คลิ๊กที่ activated เพื่อยืนยันของมูลสิทธิ์การเข้าถึงโฮสต์ และเลือก connector เพื่อเชื่อมต่อระบบ -->

**ปัญหาที่พบ**
**Error: 1#**
Winrs error:The WinRM client cannot process the request. If the authentication scheme is different from Kerberos, or if the client computer is not joined to a domain, then HTTPS transport must be used or the destination machine must be added to the TrustedHosts configuration setting. Use winrm.cmd to configure TrustedHosts. Note that computers in the Trusted

Hosts list might not be authenticated. You can get more information about that by running the following command: winrm help config.

**สาเหตุ**
    ติดเรื่องสิทธิ์การใช้งาน ทำให้เข้าใช้งานไม่ได้

**แก้ไขโดย**
Run command : 
    ```
    Set-Item wsman:\localhost\client\trustedhosts * -Force
    ```

**Error : 2#**
Winrs error:The SSL connection cannot be established. Verify that the service on the remote host is properly configured to listen for HTTPS requests. Consult the logs and documentation for the WS-Management service running on the destination, most commonly IIS or WinRM. If the destination is the WinRM service, run the following command on the destination to analyze and configure the WinRM service: "winrm quickconfig -transport: HTTPs".

Run command : 
    ```
    winrm quickconfig -transport:https
    ```
    
> PS D:\Download> winrm quickconfig -transport:https

    WinRM service is already running on this machine.

        WSManFault

            Message

                ProviderFault

                    WSManFault

    Message = Cannot create a WinRM listener on HTTPS because this machine does not have an appropriate certificate. To be used for SSL, a certificate must have a CN matching the hostname, be appropriate for Server Authentication, and not be expired, revoked, or self-signed.

Error number: -2144108267 0x80338115

Cannot create a WinRM listener on HTTPS because this machine does not have an appropriate certificate. To be used for SSL, a certificate must have a CN matching the hostname, be appropriate for Server Authentication, and not be expired, revoked, or self-signed.

**สาเหตุ**
    ไม่พบ Certificate หรือ Certificate ไม่ตรงกับชื่อที่ใช้งานไม่ตรงกัน

**แก้ไข**
    ติดตั้ง Certificate ให้ถูกต้องตามขั้นตอนที่ได้สร้างไว้ให้ ในข้อ 3.3


**Error : 3#**
Winrs error:The server certificate on the destination computer (##DNS Lable Name##:5986) has the
following errors: The SSL certificate contains a common name (CN) that does not match the hostname.

**แก้ไขโดย**
เข้า Powershell ให้ run command ตามนี้
1. แสดงรายการ listener
    ```
    dir wsman:\localhost\listener
    ```
2. ลบข้อมูล Listener HTTPS เก่าออกก่อน
    ```
    Remove-Item -Path WSMan:\localhost\Listener\Listener_1305953032 –Recurse
    ```
3. เพิ่ม Listener HTTPS ใหม่เข้าไป
    ```
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force
    ```
4. Run Script ทดสอบอีกครั้ง

**อ้างอิงจาก**
· https://4sysops.com/archives/powershell-remoting-over-https-with-a-self-signed-ssl-certificate/
· https://support.microsoft.com/en-us/help/2019527/how-to-configure-winrm-for-https · https://docs.microsoft.com/en-us/dotnet/framework/wcf/feature-details/how-to-view-certificates-with-the-mmc-snap-in#to-view-certificates-for-the-current-user
