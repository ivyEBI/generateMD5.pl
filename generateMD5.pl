#!/bin/perl

use strict;
use warnings;
my $parameterFile = $ARGV[0];
open (my $commandFile,$parameterFile);
my @parameterArray;
my $count = -1;
while (<$commandFile>){
	chomp;
        $count++;
	my @para = split(/\s+/,$_);
        $parameterArray[$count][0] = $para[0];
        $parameterArray[$count][1] = $para[1];
}
my @resultPEA =`mysql -u$parameterArray[0][0] -p$parameterArray[0][1] -hpg-mysql-vault-ega-drupal.ebi.ac.uk -P4357 prod_ega_accounts -e "select file_name,stable_id from prod_ega_accounts.file where length(unencrypted_md5) <> 32"`;
my $row_count =0;
foreach my $row (@resultPEA){
        $row_count++;
        next if ($row_count ==1);
	my @ele = split(/\s+/,$row);
	my $file ="/fire/A/ega/vol1/".$ele[0];
	my $command =  "/nfs/ega/private/ega/production/ext/gnupg-1.4.5/bin/gpg --no-tty --homedir /nfs/ega/private/ega/production/CVS/ega-configurations/.gnupg --batch -q --passphrase-file /nfs/ega/private/ega/work/saif/CVS_LOCAL/ega-configurations/keys/CGP_internal -d ".$file."| md5sum > /nfs/ega/private/ega/work/ivy/code/test_md5";
	system($command);
        open THEFILE, "</nfs/ega/private/ega/work/ivy/code/test_md5"; 
        my $firstLine = <THEFILE>;
        close THEFILE;
	my @ele1 = split(/\s+/,$firstLine);
	my @md5s = `mysql -u$parameterArray[1][0] -p$parameterArray[1][1] -hpg-mysql-vault-ega-prod -P4189 ega_audit_ve_vault_archive_test -e "select md5_checksum from audit_md5 where file_stable_id = '$ele[1]' and process_step = 'Archived_file unencrypted MD5'"`;
        chomp($md5s[1]);
	if ($ele1[0] eq $md5s[1]){
            my $command1 = `mysql -u$parameterArray[2][0] -p$parameterArray[2][1] -hpg-mysql-vault-ega-drupal.ebi.ac.uk  -P4357 prod_ega_accounts_test -e "update file set unencrypted_md5='$ele1[0]' where stable_id ='$ele[1]'"`;
            
        }else{print $ele[1],"---- mismatch\n"}
}

