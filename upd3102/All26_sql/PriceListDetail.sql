if exists(select 1 from sys.sysprocedure where proc_name = 'PriceListAptekaDetail') then
   drop procedure PriceListAptekaDetail
end if
/


create procedure PriceListAptekaDetail
(
 @ID numeric(10),
 @TMCID numeric(10)
 )
as
begin
        --Name,
 select IDD, TMCID, GroupID, BarCode, PriceP, VAT, WareCost,WareVAT, KindRound, MinQuantity,
        PricePAll, TFS, TypeTMC, MeasureName, substring(MeasureName,charindex(char(160),MeasureName)+1,30) As Series1,
        convert(datetime,substring(MeasureName,1,charindex(char(160),MeasureName)-1),104) as DateEnd, 
        convert(datetime,substring(Series1,1,charindex(char(160),Series1)-1),104) as DateOpen, 
        --substring(Series1,charindex(char(160),Series1)+1,30) as Series, do 201806
        substring(Series1,charindex(char(160),Series1)+1,30) as Series2,
        convert(varchar(30),substring(Series2,1,charindex(char(160),Series2)-1)) as CellNumber,
        substring(Series2,charindex(char(160),Series2)+1,30) as Series,
        Rest,
        convert(numeric(19,4),
        (select isnull(sum(OrderContents.Quantity),0) 
         from Orders, OrderContents 
         where Orders.Status in (-6,6,-7,7) and //in (6,7,8) and
               Orders.Kind=0 and
               OrderContents.OrdersIDD=Orders.IDD and
               OrderContents.TMCID=PriceList.TMCID and
               OrderContents.MeasureName=PriceList.MeasureName)) Reserv,
        PriceF       
 from PriceList
 where PriceList.LocWareHouseID=@ID and
       PriceList.TMCID=@TMCID

/*
                  DS.FieldValues['Quantity'],
                  DS.FieldValues['MinQuantity'],
                  DS.FieldValues['PriceP'],
                  DS.FieldValues['PriceP'],
                  DS.FieldValues['PricePAll'],
                  DS.FieldValues['VAT'],
                  DS.FieldValues['TFS'],
                  DS.FieldValues['WareCost'],
                  DS.FieldValues['WareVAT'],
                  DS.FieldValues['TypeTMC'],
                  DS.FieldValues['KindRound'],
                  DS.FieldValues['Name'],
                  DS.FieldValues['MeasureName']
*/

 return 1
end
/
grant execute on PriceListAptekaDetail to PUBLIC
/
