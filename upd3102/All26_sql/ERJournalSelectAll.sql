if exists(select 1 from sys.sysprocedure where proc_name = 'ERJournalSelectAll') then
   drop procedure ERJournalSelectAll
end if
/


create procedure ERJournalSelectAll 
(
  @DateFrom    datetime,
  @DateTo      datetime,
  @WareHouseID numeric(10), --   -1 для всех
  @Kind        smallint,
  @ID          numeric(10)=-1 --  -1 для всех
 )
as
begin
  declare @Result int
   select @DateTo=dateadd(dd,1,@DateTo)

   select J.ID,J.Kind,J.DateSet,
          CV.LentaID,CV.Number,
          case when J.Kind=1 then convert(varchar(150),'Запрос рецептов') 
                             else (select isnull(min(Pr.Name),'')
                                   from ERPrescription Pr
                                   where Pr.ID=J.PrescriptionID ) end as TMC,
           J.Quantity,
           W.Name as Cashier,
           P.FIO,
           P.Barcode,
           J.DispenseID,
           J.PatientID,
           J.PrescriptionID                          
           
   from ERJournal J,CashVoucher CV, WHMRP W, ERPatient P 
   where J.DateSet between @DateFrom and @DateTo and
          (J.Kind=@Kind or @Kind=-1) and
          (J.ID=@ID or @ID=-1) and
          CV.IDD=J.CashVoucherIDD and
          (CV.WareHouseID=@WareHouseID or @WareHouseID=-1) and
          W.ID=CV.WHMRPID and
          P.ID=J.PatientID
           
   select @result=@@error      
   if @result!=0 and @result>17000
   raiserror  @Result
  
  return 1
end
/
grant execute on ERJournalSelectAll to PUBLIC
/
