if exists(select 1 from sys.sysprocedure where proc_name = 'PriceListAptekaSelectDop') then
   drop procedure PriceListAptekaSelectDop
end if
/


create procedure PriceListAptekaSelectDop
(
 @ID numeric(10),
 @TMCID numeric(10)
)
as
begin


 select PriceList.*
 from  AddTMC,
       PriceList,
 where AddTMC.TMCID=@TMCID and
       AddTMC.Quantity=0 and
       PriceList.LocWareHouseID=@ID and
       PriceList.TMCID=AddTMC.STMCID and
       PriceList.PricePAll=(select min(P.PricePAll) from PriceList P where P.LocWareHouseID=@ID and P.TMCID=AddTMC.STMCID and P.Rest>0)

 return 1
end
/
grant execute on PriceListAptekaSelectDop to PUBLIC
/
