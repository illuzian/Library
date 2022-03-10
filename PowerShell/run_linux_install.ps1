param (
    $VMIPsCSV = "C:\Users\user\HostMapIP.csv", # CSV list of IPs to run script against with heading IP
    $SSHKey = 'C:\Users\user\.ssh\key', # SSH private key for auth
    $RPM = "C:\Users\user\package.rpm", # RPM to scp for Red Hat based hosts
    $DEB = "C:\Users\user\package.deb", # DEB to scp for Debian based hosts
    $INSTSC = "C:\Users\user\install.sh", # Install script to scp and run on the remote machine
    $VerboseOut = $true,
    $USER = "User" # User to authenticate as

)

$Hosts = import-csv -path $VMIPsCSV

foreach ($TargetHost in $hosts) {
    $IP = $TargetHost.ip


        
        scp -o StrictHostKeyChecking=no -i $SSHKey $RPM "${USER}@${IP}:"
        scp -o StrictHostKeyChecking=no -i $SSHKey $DEB "${USER}@${IP}:"
        scp -o StrictHostKeyChecking=no -i $SSHKey $INSTSC "${USER}@${IP}:install.sh"
        ssh -o StrictHostKeyChecking=no -i $SSHKey user@$IP "sh ~/install.sh"
        ssh -o StrictHostKeyChecking=no -i $SSHKey user@$IP "rm ~/install.sh"





    

}
