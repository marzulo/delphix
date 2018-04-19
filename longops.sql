COLUMN sid FORMAT 99999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A30
COLUMN progress_pct FORMAT 999.00
COLUMN elapsed_min FORMAT 9999
COLUMN elapsed_sec FORMAT 00
COLUMN remaining_min FORMAT 9999
COLUMN remaining_sec FORMAT 00
set lines 300
set pages 500

SELECT s.sid,
       s.serial#,
       s.machine,
       ROUND(sl.elapsed_seconds/60) elapsed_min, MOD(sl.elapsed_seconds,60) elapsed_sec,
       ROUND(sl.time_remaining/60) remaining_min, MOD(sl.time_remaining,60) remaining_sec
       , ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   v$session s,
       v$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.serial# = sl.serial#
AND    sl.totalwork <> 0;
