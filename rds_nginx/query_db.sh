#!/bin/bash
QUERY_RESULT=$(mysql -h $DB_HOST -u $db_user -p $DB_PASSWORD -D $DB_NAME -e "SELECT * FROM information_schema.tables LIMIT 3;" 2>&1)
echo "Query Result: $QUERY_RESULT"
