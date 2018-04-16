<?php
xhtmlHeaders(__FILE__, translate('ExportConfig') );
?>
<!DOCTYPE html>
 <html>
      <head>
           <title>Backup Config ZoneMinder</title>
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
                <h2 align="center">Backup Config ZoneMinder</h2>
                <h3 align="center">Are you sure want to export this configuration to your computer?</h3>
                <br />
                <form method="post" action="skins/classic/views/exportconfig.php" align="center">
                    <div id="contentButtons">
                        <input type="submit" name="Export" value="Export" />
                        <input type="button" value="Close" onclick="closeWindow()" />
                    </div>
                </form>
      </body>
 </html>
