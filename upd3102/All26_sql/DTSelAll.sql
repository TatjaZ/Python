if exists(select 1 from sys.sysprocedure where proc_name = 'DTSelectAll') then
   drop procedure DTSelectAll
end if
/


create procedure DTSelectAll
(@IsDiscount smallint,@IsLocal smallint) 
as 
begin 
/*
 @IsDiscount=-2 ������ ���� ������
 @IsDiscount=-1 ��� ����
 @IsDiscount=0 ������
 @IsDiscount=1 ��������
 @IsDiscount=3 ������ (��� �����)
*/

 --!!!������ ��� �����
if @IsDiscount!=3
  select @IsDiscount=-1


 if @IsLocal=1
 select *
 from DiscountTypes
 where ID<0 and 
       OnOff=1 and
       (IsDiscount=@IsDiscount or @IsDiscount=-1 or (@IsDiscount=-2 and IsDiscount!=1) )
 else
 select *
 from DiscountTypes
 where ID>0 and 
       OnOff=1 and
       (IsDiscount=@IsDiscount or @IsDiscount=-1 or (@IsDiscount=-2 and IsDiscount!=1) ) 

 return 1 
end
/
grant execute on DTSelectAll to PUBLIC
/
