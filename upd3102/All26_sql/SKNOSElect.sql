if exists(select 1 from sys.sysprocedure where proc_name = 'SKKODocumentSelect') then
   drop procedure SKKODocumentSelect
end if
/


create procedure SKKODocumentSelect 
(
 @ID numeric(10),
 @Kind smallint,
 @SourceID numeric(10),
 @CashNumber varchar(15) //2019 12
)
as
begin
/*   ��.���������
     ��. �������� �������� ������� SKKODocument     
*/
 declare @Result int 
 
 if @ID!=0 
  select ID, LentaID, CashNumber, Kind, SourceID, UIDStr, DateU 
  from SKKODocument 
  where ID=@ID and
        CashNumber=@CashNumber //2019 12
 else /* ����� ������ ��� ������������� - ������ ������������ ��� ������ ���� */
  
  select ID, LentaID, CashNumber, Kind, SourceID, UIDStr, DateU 
  from SKKODocument 
  where Kind=@Kind and
        SourceID=@SourceID
   
 select @result=@@error   

 if @result!=0
   raiserror  @Result


  return 1
 
end
/
grant execute on SKKODocumentSelect to PUBLIC
/


if exists(select 1 from sys.sysprocedure where proc_name = 'SKKODocumentAlter') then
   drop procedure SKKODocumentAlter
end if
/


create procedure SKKODocumentAlter 
(
 @LentaID numeric(10),
 @CashNumber varchar(15),
 @Kind smallint,
 @SourceID numeric(10),
 @UIDStr char(24) out,
 @ID numeric(10) out
)
as
begin
/*   ��.���������
     ��. �������� �������� ������� SKKODocument     
*/
 declare @Result int 

 if @Kind=6
   select @ID=@SourceID*(-1)

  
 
 
 if @ID<0 and @LentaID=0 and @Kind=0 and @SourceID=0
  begin 
   delete SKKODocument 
   where ID=abs(@ID)
   
   select @result=@@error   
  
  end

  else
 
 if @ID!=0 and
    @UIDStr!='' and //2018 04 ��� ���������� ��������� ���������� �������� ����� ���� ����� ������� � ��������� �� �������� ���
    exists(select 1 from SKKODocument where ID=@ID and CashNumber=@CashNumber) //2018 08 �������  CashNumber=@CashNumber ����� ����� ������ ������ ����� � ������� �� �������
  begin 
   update SKKODocument 
    set UIDStr=@UIDStr
   where ID=@ID and  CashNumber=@CashNumber
   
   select @result=@@error   
  
  end

  else
 --��� ������������� ��������� � ������� ��� ���������� ����� � ������ ��������������
 if exists(select 1 from SKKODocument where Kind=@Kind and SourceID=@SourceID and LentaID=@LentaID and CashNumber=@CashNumber)
  begin 
   select @UIDStr=UIDStr, @ID=ID
   from SKKODocument 
   where Kind=@Kind and 
         SourceID=@SourceID and 
         LentaID=@LentaID and 
         CashNumber=@CashNumber
   
   select @result=@@error   
  
  end
  else
 
  begin 
   --����� ������       
   if @ID=0 
    select @ID=isnull(max(ID),0)+1 from SKKODocument where CashNumber=@CashNumber and ID>0 -- where Kind!=6 ID>0 � ������ ���� ���������� � �������� �����
   
   insert into SKKODocument(ID, LentaID, CashNumber, Kind, SourceID, UIDStr)
    values(@ID,@LentaID, @CashNumber, @Kind, @SourceID, @UIDStr)
   
   select @result=@@error 
    
  end

 if @result!=0 --and @result>17000
   raiserror  @Result


  return 1
 
end
/
grant execute on SKKODocumentAlter to PUBLIC
/
