
<!DOCTYPE html>
<html>
    <body>
        <?php
           $outputMessage = 'Initial value';  
           include 'include/connect.php'; // Connect to the database

           if (! $dbconn ) {
               echo 'Connection failed '.pg_last_error();
            } else {
               $player_id = $_POST['player_id'];
               $player_command = "CALL rps.proc_insert_player($1, NULL)";
               
               $result = pg_query_params($dbconn, $player_command, array($player_id));

            if (!$result) {
                echo "Error in procedure call: " . pg_last_error();
            } else {

                $errlvl = pg_fetch_row($result)[0];
                if($errlvl == '0') {
                    $outputMessage = 'Success';
                } else
                    if($errlvl == '1') {
                    $outputMessage = 'Invalid parameter';
                } else
                    if($errlvl == '2') {
                    $outputMessage = 'Duplicate PLayer';
                } else {
                    $outputMessage = "Unrecognized return code";
                }
            }
            pg_close($dbconn); // Close the connection
            echo $outputMessage;
        }    
        ?> // HTML boiler plate
     <form action="/index.html">
            <div>
                <textarea class="message" name="feedback" text-align: center;
                        id="feedback" rows=1 cols=80 readonly="enabled">
                    <?php echo $outputMessage; ?>
                </textarea>
            </div>
                <button type="submit">Return</button>
        </form>
    </body>
</html>