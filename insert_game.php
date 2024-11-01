
<!DOCTYPE html>
<html>
    <body>
        <?php
            $output = 'Initial value';  
            include 'include/connect.php'; // Connect to the database

            if (! $dbconn ) {
                echo 'Connection failed '.pg_last_error();
            } else {
                $player1_id = $_POST['player1_ID'];
                $player2_id = $_POST['player1_ID'];
                $player_command = "CALL rps.proc_insert_game($1, $2, NULL)";

                $result = pg_query_params($dbconn, $player_command, array($player1_id, $player2_id));

            if (!$result) {
                echo "Error in procedure call: " . pg_last_error();
            } else {
                $errlvl = pg_fetch_row($result)[0];

                if($errlvl == '0') {
                    $outputMessage = 'Success';
                } else
                    if($errlvl == '1') {
                    $outputMessage = 'Invalid parameters';
                } else
                    if($errlvl == '2') {
                    $outputMessage = 'Foreign Key Violation';
                } else
                    if($errlvl == '3') {
                    $outputMessage = 'Unique game violation';
                } else {
                    $outputMessage = "unrecognized return code";
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
                    <?php echo $output; ?>
                </textarea>
            </div>
                <button type="submit">Return</button>
        </form>
    </body>
</html>