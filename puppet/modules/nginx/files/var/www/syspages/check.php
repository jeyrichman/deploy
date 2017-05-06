<?php

if (extension_loaded('newrelic')) {
    newrelic_ignore_transaction (TRUE);
    newrelic_ignore_apdex (TRUE);
}

echo "ok";

?>