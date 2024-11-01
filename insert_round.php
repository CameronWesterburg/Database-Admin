
<!DOCTYPE html>
<html>
    <body>
        <?php
            $outputMessage = 'Initial value';  
            include 'include/connect.php'; // Connect to the database

            if (! $dbconn ) {
                echo 'Connection failed '.pg_last_error();
            } else {
                $player1_id = $_POST['player1_ID'];
                $token1 = $_POST['token1']
                $player2_id = $_POST['player2_ID'];
                $token2 = $_POST['token2']
                $player_command = "CALL rps.proc_insert_round($1, $2, $3, $4, NULL)";

                $result = pg_query_params($dbconn, $player_command, array($player1_id, $token1, $player2_id, $token2)); 

                if (!$result) {
                    echo "Unable to CALL procedure: " . pg_last_error();
                } else {
                    $errlvl = pg_fetch_row($result)[0];

                    if($errlvl == '0') {
                        $outputMessage = 'Success';
                    } else
                        if($errlvl == '1') {
                        $outputMessage = 'No game exists';
                    } else
                        if($errlvl == '2') {
                        $outputMessage = 'Invalid token';
                    } else {
                        $outputMessage = 'Unrecognized return code';
                    }
                }
                pg_close( $dbconn );
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