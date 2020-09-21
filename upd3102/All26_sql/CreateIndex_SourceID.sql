if exists(select 1 from sys.sysindex where index_name='SourceID_idx') then
   drop index SourceID_idx
end if
/

create  index SourceID_idx on SKKODocument (
Kind ASC,
SourceID ASC
)
/