<?php
$message = '';
if(isset($_POST["import"]))
{
 if($_FILES["database"]["name"] != '')
 {
  $array = explode(".", $_FILES["database"]["name"]);
  $extension = end($array);
  if($extension == 'sql')
  {
   $connect = mysqli_connect("localhost", "root", "root", "zm");
   $output = '';
   $count = 0;
   $file_data = file($_FILES["database"]["tmp_name"]);
   foreach($file_data as $row)
   {
    $start_character = substr(trim($row), 0, 2);
    if($start_character != '--' || $start_character != '/*' || $start_character != '//' || $row != '')
    {
     $output = $output . $row;
     $end_character = substr(trim($row), -1, 1);
     if($end_character == ';')
     {
      if(!mysqli_query($connect, $output))
      {
       $count++;
      }
      $output = '';
     }
    }
   }
   if($count > 0)
   {
    $message = '<label class="text-danger">There is an error in Import</label>';
   }
   else
   {
    $message = '<label class="text-success">Monitor Successfully Imported</label>';
   }
  }
  else
  {
   $message = '<label class="text-danger">Invalid File</label>';
  }
 }
 else
 {
  $message = '<label class="text-danger">Please Select Monitor File</label>';
 }
}
xhtmlHeaders(__FILE__, translate('ImportMonitor') );
?>

<!DOCTYPE html>
<html>
 <head>
  <title>Import Monitor From Backup</title>
  <link rel="icon" type="image/ico" href="graphics/favicon.ico">
  <link rel="shortcut icon" href="graphics/favicon.ico">
  <link rel="shortcut icon" href="graphics/favicon.ico">
  <link rel="stylesheet" href="css/overlay.css" type="text/css">
  <link rel="stylesheet" href="css/bootstrap.min.css" type="text/css">
  <link rel="stylesheet" href="skins/classic/css/classic/skin.css" type="text/css" media="screen">
  <link rel="stylesheet" href="skins/classic/css/classic/views/console.css" type="text/css" media="screen">
  <script type="text/javascript" src="tools/mootools/mootools-core.js"></script>
  <script type="text/javascript" src="tools/mootools/mootools-more.js"></script>
  <script type="text/javascript" src="js/mootools.ext.js"></script>
  <script type="text/javascript" src="skins/classic/js/jquery.js"></script>
  <script type="text/javascript" src="js/overlay.js"></script>
  <script type="text/javascript" src="skins/classic/js/classic.js"></script>
  <script type="text/javascript" src="skins/classic/js/skin.js"></script>
  <script type="text/javascript" src="skins/classic/views/js/monitorprobe.js"></script>
 </head>
 <body>
  <br /><br />
  <div class="container" style="width:400px;">
   <h2 align="center">Import ZoneMinder Monitor</h2>
   <br />
   <div><?php echo $message; ?></div>
   <form method="post" enctype="multipart/form-data">
    <p align="left"><label>Select Monitor File</label>
    <input type="file" name="database" style="width: 370px" /></p>
    <div id="contentButtons">
    <input type="submit" name="import" value="Import" />
    <input type="button" value="Close" onclick="closeWindow()" />
    </div>
  </form>
  </div>
 </body>
</html>
