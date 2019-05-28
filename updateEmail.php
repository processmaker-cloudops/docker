<?php
var_dump($argv[1]);
var_dump($argv[2]);
// Define constants to be used
define('PATH_INSTALLED_FILE', '/opt/processmaker/workflow/engine/config/paths_installed.php');
define('PATH_GULLIVER_SYSTEM_G', '/opt/processmaker/gulliver/system/class.g.php');
try {
    // Check if the file PATH_INSTALLED_FILE exists
    if (file_exists(PATH_INSTALLED_FILE)) {
        require_once PATH_INSTALLED_FILE;
        require_once PATH_GULLIVER_SYSTEM_G;
        list($server, $user, $pass) = explode(SYSTEM_HASH, G::decrypt(HASH_INSTALLATION, SYSTEM_HASH));
        // Open connection in MySQL Server
        $link = mysqli_connect($server, $user, $pass);
        if (!$link) {
            throw new Exception(mysqli_error());
        }
        mysqli_query($link,"UPDATE wf_$argv[1].RBAC_USERS SET USR_EMAIL = '$argv[2]'");
        mysqli_query($link,"UPDATE wf_$argv[1].USERS SET USR_EMAIL = '$argv[2]'");
                mysqli_close($link);
    } else {
        // Exception if file does not exist
        throw new Exception(PATH_INSTALLED_FILE . ' doesn\'t exist.');
    }
} catch (Exception $error) {
    echo $error->getMessage() . "\n";
    @mysqli_close($link);
}