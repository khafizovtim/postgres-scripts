#include <stdio.h>
#include "postgres.h"
#include "utils/builtins.h"
#include "utils/wait_event.h"

PG_MODULE_MAGIC;
PG_FUNCTION_INFO_V1(waitevent_by_number);

Datum waitevent_by_number(PG_FUNCTION_ARGS)
{
 int waitevent = PG_GETARG_INT32(0);
 char *waiteventname=(char *)palloc(50);
 sprintf(waiteventname,"%s_%s",pgstat_get_wait_event_type(waitevent),pgstat_get_wait_event(waitevent));
 PG_RETURN_TEXT_P(cstring_to_text(waiteventname));
}
