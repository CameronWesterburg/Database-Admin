<?php
    // It's OK to use this file as is so long as you understand how
    // it works.

    // Best practice puts this file in a private directory such that the
    // web server has EXECUTE permissions and that's all.  When it is
    // included, use an absolute path.

    $host   = "host = 127.0.0.1";
    // Our web server and database server are on the same machine; this wouldn't be
    // a good idea in a production setting.
    
    $port   = "port = 5432";
    $dbname = "dbname = db55";
    
    $credentials = "user = jqpublic password=Blu3Ski3s"; // public user
    // Important: The application is designed to run as the public
    // user.  The admin user's credentials should be deleted from
    // the file!
    
    // building connection argument string
    $connstring = $host ." ". $dbname  ." ". $credentials;
		
    $dbconn = pg_connect("$connstring");	// connect to DB

    // Wipe all of the strings to ensure we will send nothing back except
    // $dbConn (the connection).  This is always a good practice in PHP!
    unset($host);
    unset($port);
    unset($dbname);
    unset($credentials);
    unset($connString);
?>