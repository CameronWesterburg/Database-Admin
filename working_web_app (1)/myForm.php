<!DOCTYPE html>
<html>
    <body>
        <?php
            $output = 'Initial value'; 
            // I always like for a variable to have an assigned value.
            
            include 'include/connect.php'; // or "require"  returns $dbconn
            /*
                I prefer "include" to "require" because, if "require" fails to
                connect, it dies without any message.  If "include" fails, it 
                continues, hits the test for a NULL $dbconn, and displays the
                error message.
            */
            if (! $dbconn ) 
                echo 'Connection failed '.pg_last_error(); // check the connection
                // This is the end of the logic.  Do not use "die"!
            else
            {
                /*    
                    Get the parameters from the web page.  HTML will allow a form field to be type "number", but text is the default.
                    
                    In general, your psql procedures should be written to
                    accept only character data.  Trying to receive numeric
                    data from a web page will complicate your life.  Receive
                    it as character data and convert it on the server side.
                */
                $fee = $_POST['fee']; 
                $fie = $_POST['fie'];
/*
    In the assignment, the number of parameters will vary; however,
    the last parameter (INOUT parm_errlvl SMALLINT) will be handled
    the same way for all of them.  Do not name your parameters like
    mine.  Use meaningful names
*/

                $comstring = "CALL rps.proc_insert_generic($1, $2, NULL)";
                /*
                    DO NOT CALL proc_insert_generic!  That is for demonstration,
                    only!  Your php calls one of the three procedures we developed
                    for the rps schema.  This procedure has two parameters.  You
                    must deal with other procedural signatures.
                    
                    The INOUT parameter will be the same, though.  It's OK to
                    follow this code closely... it works and represents a
                    simple front end.  You have three procedures, so you will
                    have three different .php scripts.
                */
               
                $result = pg_query_params($dbconn, $comstring, array($fee, $fie));

                // Check that the procedure call was successful:
                if( ! $result )
                    echo 'Unable to CALL stored function: '.pg_last_error();
                    /*
                        Do not use "return", "exit" or "die".  Your rouutine
                        exits normally by reaching its logical end!
                    */
                        
                else
                {
                    $errlvl = pg_fetch_row($result)[0];
                    /*                        
                        I am combining:                       
                            $row = pg_fetch_row($result);

                            $parm_out = $row[0]; // this is the first INOUT parmeter. 
                                 //A 2nd INOUT parmeter
                                 // would be $row[1] & so on... if we had any more.
                        from the previous example.
                        
                        Just read the PHP documentation on type casting at 
                        https://www.php.net/manual/en/language.types.type-juggling.php

                        So... $errlvl tells our php script what happened when
                        the procedure ran.  It receives the INOUT parm_errlvl;
                        however, when it comes into the php script, it's text.
                    
                        That makes no difference to us, since it's a zero, one, 
                        or two.  All we do is quote it.
                    
                        Here we parse the procedure's output and provide meaningful
                        output to the web user.
                    */
                
                    if($errlvl == '0') // note the quotes!  It's text.
                        $output = 'Success';
                    else
                        /*
                            Here is another place your code will differ.  You
                            will code your the result passed back in parm_errlvl.
                            (read the sql code to get the integers it passes back.)
                            Use this as an example, but it has to reflect the error codes returned from the procedures.
                        */
                        if($errlvl == '1')
                            $output = 'Invalid parameter';
                        else
                            if($errlvl === '2')
                            $output = 'Duplicate PK';
                        else
                            $output = 'Unrecognized return code';
                }
                pg_close( $dbconn ); // do not close until finished
                                     // with the "pg_xxx" procedure calls
                echo 'Game over, man!!!';
            }
/*
    The rest of this *may* stay the same... unless you know HTML code
    and decide to get cute.  Since I don't know much about HTML, if it
    works, it'll be fine.
    
    E.g.: you may run all three PHP scripts from a single index.html...
    or anything you want.
    
    Let's use three distinct PHP scripts:
        insert_player.php
        insert_game.php
            and
        insert_round.php
        
    Then, you may call them any way you see fit... and return however
    you think is best.
    
    This code is simply an example that displays what is in the
    $output variable and returns to index.html.
*/
        ?>
        <!-- Display the output & go back to start -->
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
