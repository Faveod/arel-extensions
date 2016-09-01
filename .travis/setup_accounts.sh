#!/bin/bash

set -ev

"$ORACLE_HOME/bin/sqlplus" -L -S / AS SYSDBA <<SQL
@@test/support/alter_system_user_password.sql
@@test/support/create_oracle_enhanced_users.sql
exit
SQL