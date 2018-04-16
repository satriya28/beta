<?php
      //export.php
 if(isset($_POST["export"]))
 {
 $DBUSER="root";
 $DBPASSWD="root";
 $DATABASE="zm";
 $TABLE="Config";

 $file_name = 'zm-config-backup-' . date('y-m-d') . '.sql';
 header('Content-Type: application/octet-stream');
 header('Content-Disposition: attachment; filename=' . basename($file_name));

 $cmd = "mysqldump -u $DBUSER --password=$DBPASSWD $DATABASE $TABLE";
 passthru( $cmd );
 exit(0);
}
?>
