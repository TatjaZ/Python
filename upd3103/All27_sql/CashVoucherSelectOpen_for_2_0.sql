if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherSelectOpen') then
   drop procedure CashVoucherSelectOpen
end if
/


create procedure CashVoucherSelectOpen 
(@CashNumber varchar(15),@LentaID numeric(10),@Number integer)
as
begin

 if @Number=0 
  begin
   select V.IDD,V.CashNumber,V.LentaID,V.Number,V.WHMRPID,V.VoucherDate,V.VoucherTime,V.WareHouseID,V.Status,V.Kind,V.CustomerID,
          WHMRP.Name Casher,WareHouse.Name WareHouse,
          --WHNomenclatureGroup.Name CustomerName,
          case 
             when V.CustomerID<=0 then (select WHNomenclatureGroup.Name from WHNomenclatureGroup where WHNomenclatureGroup.ID=V.CustomerID)
              else convert(varchar(40), (select P.Name from WHMRP P where P.ID=V.CustomerID) )
          end CustomerName,    
          (select convert(numeric(18,2),isnull(sum(C.CostN),0)) from CashVoucherContents C  where C.CashVoucherID=V.IDD) Sum
   from CashVoucher V (index CashVoucher_idx1),
        WHMRP,
        WareHouse --,  WHNomenclatureGroup
   where V.LentaID=@LentaID and
         V.CashNumber=@CashNumber and
         --V.Status=0 and  для 1.5 !!!
         V.Status in (0,5) and --!!! только для блоков управления!
         WHMRP.ID=V.WHMRPID and
         WareHouse.ID=V.LocWareHouseID 
         --and WHNomenclatureGroup.ID=V.CustomerID
     
  end 
 else
  begin
   select V.IDD,V.CashNumber,V.LentaID,V.Number,V.WHMRPID,V.VoucherDate,V.VoucherTime,V.WareHouseID,V.Status,V.Kind,V.CustomerID,
          WHMRP.Name Casher,WareHouse.Name WareHouse,
          --WHNomenclatureGroup.Name CustomerName,
          case 
             when V.CustomerID<=0 then (select WHNomenclatureGroup.Name from WHNomenclatureGroup where WHNomenclatureGroup.ID=V.CustomerID)
              else convert(varchar(40), (select P.Name from WHMRP P where P.ID=V.CustomerID) )
          end CustomerName,          
          (select convert(numeric(18,2),isnull(sum(C.CostN),0)) from CashVoucherContents C  where C.CashVoucherID=V.IDD) Sum
   from CashVoucher V (index CashVoucher_idx1), 
        WHMRP, 
        WareHouse--, WHNomenclatureGroup
   where V.LentaID=@LentaID and
         V.CashNumber=@CashNumber and
         V.Number=@Number and 
         WHMRP.ID=V.WHMRPID and
         WareHouse.ID=V.LocWareHouseID
         -- and WHNomenclatureGroup.ID=V.CustomerID
  end 

 return 1 
end
/
grant execute on CashVoucherSelectOpen to PUBLIC
/
