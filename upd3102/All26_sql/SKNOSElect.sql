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
/*   Вх.параметры
     см. описание столбцов таблицы SKKODocument     
*/
 declare @Result int 
 
 if @ID!=0 
  select ID, LentaID, CashNumber, Kind, SourceID, UIDStr, DateU 
  from SKKODocument 
  where ID=@ID and
        CashNumber=@CashNumber //2019 12
 else /* поиск только при аннулировании - нельзя использовать для поиска смен */
  
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
/*   Вх.параметры
     см. описание столбцов таблицы SKKODocument     
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
    @UIDStr!='' and //2018 04 для правильной обработки повторного закрытия смены если рубят питание и закрывают по несколку раз
    exists(select 1 from SKKODocument where ID=@ID and CashNumber=@CashNumber) //2018 08 добавил  CashNumber=@CashNumber иначе берет запись другой кассы в аптеках на сервере
  begin 
   update SKKODocument 
    set UIDStr=@UIDStr
   where ID=@ID and  CashNumber=@CashNumber
   
   select @result=@@error   
  
  end

  else
 --уже существование документа и вернуть его внутренний номер и строку идентификатора
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
   --новая запись       
   if @ID=0 
    select @ID=isnull(max(ID),0)+1 from SKKODocument where CashNumber=@CashNumber and ID>0 -- where Kind!=6 ID>0 в случае если начинается с закрытие смены
   
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
