$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {

  $dbh->do(q{
--
-- Set relevant permissions
--
INSERT INTO permissions (module, code, description) VALUES
( 'serials',       'serial_create',  'Allow creating a single serial.'),
( 'serials',       'serial_edit',    'Allow editing the data of a single serial.'),
( 'serials',       'serial_delete',  'Allow deleting a single serial.')
;
  });

  # Always end with this (adjust the bug info)
  SetVersion( $DBversion );
  print "Upgrade to $DBversion done (Bug 22094 - REST API: Add endpoint /serials)\n";
}