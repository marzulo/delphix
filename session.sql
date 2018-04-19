SET LINESIZE 300
COLUMN spid FORMAT A10
COLUMN username FORMAT A10
COLUMN program FORMAT A45
set pages 500

--ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;

SELECT s.inst_id,
       s.sid,
       s.serial#,
       p.spid,
       s.username,
       s.program
FROM   gv$session s
       JOIN gv$process p ON p.addr = s.paddr AND p.inst_id = s.inst_id
WHERE  s.type != 'BACKGROUND';


col STATUS format a9
col hrs format 9999.99
select SESSION_KEY, INPUT_TYPE, STATUS,
 to_char(START_TIME,'mm/dd/yy hh24:mi') start_time,
 to_char(END_TIME,'mm/dd/yy hh24:mi') end_time,
 elapsed_seconds/3600 hrs
 from V$RMAN_BACKUP_JOB_DETAILS
 order by session_key;

