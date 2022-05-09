function Invoke-UDFSQLCommand{
    param(
         [parameter(mandatory)]		[string[]]$InstanceName,
		 [parameter(mandatory)]		[string]$DatabaseName,
									[string]$TsqlCommand,
									[string]$ProcessName = "Invoke-UDFSQLCommand"
    )

    # sql connection to instance
	foreach($instance in $instancename){
		$sqlconnectionstring = "
			server                          = $instance;
			database                        = $databasename;
			trusted_connection              = true;
			application name                = $processname;"
		# sql connection, setup call
		$sqlconnection                  = new-object system.data.sqlclient.sqlconnection
		$sqlconnection.connectionstring = $sqlconnectionstring
		$sqlconnection.open()
		$sqlcommand                     = new-object system.data.sqlclient.sqlcommand
		$sqlcommand.connection          = $sqlconnection
		$sqlcommand.commandtext         = $tsqlcommand
		# sql connection, handle returned results
		$sqladapter                     = new-object system.data.sqlclient.sqldataadapter
		$sqladapter.selectcommand       = $sqlcommand
		$dataset                        = new-object system.data.dataset
		$sqladapter.fill($dataset) | out-null
		$resultsreturned               += $dataset.tables
		$sqlconnection.close()										# the session opens, but it will not close as expected
		$sqlconnection.dispose()									# TO-DO: make sure the connection does close
    }
    $resultsreturned
}
