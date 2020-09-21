if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentUpdatingDisc') then
   drop procedure CashVoucherContentUpdatingDisc
end if
/


create procedure CashVoucherContentUpdatingDisc 
(@CashVoucherID numeric(10),@DiscountExtID numeric(10),@DiscountCardID numeric(10),@Discount smallmoney,
 @DiscountSum numeric(18,2) out)
as
begin
 declare @RoundOff numeric(18,2),@Result int,
 @gtID numeric(10),@gtPriceN numeric(18,2),@gtPriceP numeric(18,2),@gtPricePAll money, @gtVAT numeric(6,2),@gtTFS numeric(6,2),
 @gtWareCost numeric(18,2),@gtWareVAT numeric(6,2),@gtQuantity numeric(19,4),@gtCostN money,
 @gtKindRound smallint,@gtDiscountSum numeric(18,2),@TMPCOST numeric(18,2),
 @IsCostNDiscount smallint,
 @Apteka smallint
   
   
 select @Apteka=1  --!!! тут меняем 0-1 

 /* !!!для аптек  для отальных закоменьтить обязательно */
 if @DiscountCardID!=0
  begin
    exec AptekaSetDiscountCard @CashVoucherID, @DiscountCardID, @Discount, @DiscountSum out
   return 1 
  end


 select @IsCostNDiscount=0

 if @CashVoucherID<0
   select @CashVoucherID=abs(@CashVoucherID), @IsCostNDiscount=1

create table #t
(
    ID                   numeric(10),
    PriceN               numeric(18,2),
    PriceP               numeric(18,2),
    PricePAll            numeric(18,2),
    VAT                  numeric(6,2),
    TFS                  numeric(6,2),
    WareCost             numeric(18,2),
    WareVAT              numeric(6,2),
    Quantity             numeric(19,4),
    CostN                numeric(18,2),
    KindRound            smallint,
    DiscountSum          numeric(18,2)
)

    
//!!! для Гума - ручная скидка при халве - остальным коментить!!!     
/*if @DiscountExtID=0 and @DiscountCardID=0 and @Discount!=0 

 insert into #t
 select ID,PriceP as PriceN, PriceP, PricePAllFix as PricePAll, VAT, TFS, WareCost,WareVAT,
        Quantity, CostN+DiscountSum as CostN, KindRound, DiscountSum
 --into #t
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID and
       PriceP>0 and 
       PriceN>0 and
       --Discount=0 and 
       --DiscountSum=0 and
       --DiscountExtID=0 and
       --DiscountCardID=0 and
       TypeTMC not in (-1,3,6,7) --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)  
       and TypeTMC<100 --для Универмага Витебск 2016 04 и для других где надо показать отдельно типы товара в зэте и не давать на это скидкинапример 105 - Подарочный сертиф.
 order by ID
else  */
//!!! для всех !!!
 insert into #t
 select ID,PriceN,PriceP,PricePAll,VAT,TFS,WareCost,WareVAT,Quantity,CostN,KindRound,DiscountSum
 --into #t
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID and
       PriceP>0 and 
       PriceN>0 and
       Discount=0 and 
       DiscountSum=0 and
       DiscountExtID=0 and
       DiscountCardID=0 and
       --TypeTMC!=3 
       TypeTMC not in (-1,3,6,7) --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)
       and TypeTMC<100 --для Универмага Витебск 2016 04 и для других где надо показать отдельно типы товара в зэте и не давать на это скидкинапример 105 - Подарочный сертиф.
       --and TypeTMC!=-1 --новое для Гума не давать скидки на прочие доплаты которые введены как услуги  
 order by ID
 
 declare gt cursor  for
 select ID,PriceN,PriceP,PricePAll,VAT,TFS,WareCost,WareVAT,Quantity,CostN,KindRound,DiscountSum
 --from CashVoucherContents
 from #t
 order by ID
        
 select @DiscountSum=0

 begin transaction

 if exists(select 1 from CashVoucher where IDD=@CashVoucherID and Status!=0) 
  begin
   rollback transaction raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 open gt
 fetch gt into @gtID,@gtPriceN,@gtPriceP,@gtPricePAll,@gtVAT,@gtTFS,@gtWareCost,@gtWareVAT,@gtQuantity,@gtCostN,@gtKindRound,@gtDiscountSum
 while @@sqlstatus=0
  begin

    --fetch gt into @gtID1,@gtPriceN1,@gtPriceP1,@gtPricePAll1,@gtVAT1,@gtTFS1,@gtWareCost1,@gtWareVAT1,@gtQuantity1,@gtCostN1,@gtKindRound1,@gtDiscountSum1        

    select @TMPCOST=@gtCostN
    
    if @IsCostNDiscount=1 --2015 07 
      begin --если скидка с суммы по позиции  а не с цены (безнал веста)
       select @gtCostN=round((@gtCostN*(1-@Discount*0.01)),2) 
       exec RulesOfRoundOff @gtKindRound,@gtCostN,@gtCostN out,@RoundOff out,@Result out
   
       select @gtPricePAll=round((@gtCostN/@gtQuantity),2)
       exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out
       select @RoundOff=round(@RoundOff*@gtQuantity,2) 
      end
    else  --end 2015 07
    begin   
     //select @gtPricePAll=round((@gtPricePAll*(1-@Discount*0.01)),4) в 2017 летом непонятно для чего аптекам сделано оруг. до4 знаков 2019 02 вернуто назад из за несогласованности с CashVoucherContentUpdatinge
     select @gtPricePAll=round((@gtPricePAll*(1-@Discount*0.01)),2)
     exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out
    
     if @Apteka=0
      exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,2),@gtCostN out,@RoundOff out,@Result out
       else
      exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,4),@gtCostN out,@RoundOff out,@Result out
    end 
     --определяем оптускную цену 
    if @Apteka=1
     select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2) 
    else       
     select @gtPriceN=round((@gtPricePAll-(@gtWareCost*(1+@gtWareVAT*0.01)))/(1+@gtTFS*0.01)/(1+@gtVAT*0.01)+(@gtWareCost*(1+@gtWareVAT*0.01)),2)
 
    select @gtDiscountSum=@TMPCOST-@gtCostN
    select @DiscountSum=@DiscountSum+@gtDiscountSum

    update CashVoucherContents
    set PriceN=@gtPriceN,
        PricePAll=@gtPricePAll,
        CostN=@gtCostN,
        RestOfRound=@RoundOff,
        DiscountExtID=case when @Discount!=0 and @DiscountExtID=0 and @DiscountCardID=0 then -100 else @DiscountExtID end, --//201805 для ясеня скидка дана кассиром ипередачи в бэк этой скидки
        DiscountCardID=@DiscountCardID,
        Discount=@Discount,
        DiscountSum=@gtDiscountSum 
    from CashVoucherContents (index Voucher_idx)
    where CashVoucherID=@CashVoucherID and ID=@gtID
   
    --select @gtID=@gtID1,@gtPriceN=@gtPriceN1,@gtPriceP=@gtPriceP1,@gtPricePAll=@gtPricePAll1,@gtVAT=@gtVAT1,
    --       @gtTFS=@gtTFS1,@gtWareCost=@gtWareCost1,@gtWareVAT=@gtWareVAT1,@gtQuantity=@gtQuantity1,@gtCostN=@gtCostN1,
    --       @gtKindRound=@gtKindRound1,@gtDiscountSum=@gtDiscountSum1  
  
    fetch gt into @gtID,@gtPriceN,@gtPriceP,@gtPricePAll,@gtVAT,@gtTFS,@gtWareCost,@gtWareVAT,@gtQuantity,@gtCostN,@gtKindRound,@gtDiscountSum  

  end 
 close gt 

 if @DiscountCardID!=0
  update CashVoucherContents
   set DiscountCardID=@DiscountCardID
  from CashVoucherContents (index Voucher_idx)
  where CashVoucherID=@CashVoucherID and
        DiscountCardID=0 and
        --TypeTMC!=3 and товары по фикс ценам тоже идут в накопления 2016 02
        TypeTMC!=-1


 commit transaction 

 return 1 
end
/
grant execute on CashVoucherContentUpdatingDisc to PUBLIC
/

if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentSetSumDiscou') then
   drop procedure CashVoucherContentSetSumDiscou
end if
/


create procedure CashVoucherContentSetSumDiscou 
(
 @CashVoucherID numeric(10),
 --@ChSum numeric(18,2),
 @DiscountSum numeric(18,2) out
)
as 
begin

 declare @RoundOff numeric(18,2), @Result int,
         @gtID numeric(10),@gtPriceN numeric(18,2),@gtPriceP numeric(18,2),@gtPricePAll money, @gtVAT numeric(6,2),
         --@gtTFS numeric(6,2),gtWareVAT numeric(6,2),
         @gtWareCost numeric(18,2),@gtQuantity numeric(19,4),@gtCostN money,
         @gtKindRound smallint,@gtDiscountSum numeric(18,2),@TMPCOST numeric(18,2),
         @gtDiscountExtID numeric(10), @gtDiscount smallmoney, @gtKindDiscont smallint,
         @CurrentDateTime datetime,
         @Apteka smallint,
         @ChSum numeric(18,2)
         -- , @DiscountTypesID numeric(10)   
 
 select @DiscountSum=0

 select @Apteka=1  --!!! тут меняем 0-1 
 
 --если уже пошла оплата то ничего не делаем
 if exists(select 1 from CashVoucherPayment where CashVoucherPayment.CashVoucherID=@CashVoucherID)
   return 1
 
        
 select @CurrentDateTime=getdate()
 
 --отменить скидки с типом 4 примененные раньше
 update CashVoucherContents
    set PriceN=CVC.PriceP,
        PricePAll=CVC.PricePAllFix,
        CostN=Round(CVC.PricePAllFix*CVC.Quantity,2),
        RestOfRound=0,
        DiscountExtID=0,
        Discount=0,
        DiscountSum=0 
    from CashVoucherContents CVC (index Voucher_idx)
    where CVC.CashVoucherID=@CashVoucherID and 
          CVC.DiscountExtID!=0 and
          (select IsDiscount from DiscountTypesExt, DiscountTypes
           where DiscountTypesExt.ID=CVC.DiscountExtID and
                DiscountTypes.ID=DiscountTypesExt.DiscountID
           )=4

 select @ChSum=isnull(sum(CostN),0) 
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID

 select ID, TMCID, PriceP, PricePAllFix PricePAll, VAT, --TFS,WareVAT,
        WareCost, Quantity, CostN+DiscountSum as CostN, KindRound, GroupID, DiscountExtID, Discount, convert(smallint,0) Kind,
        DiscountExtID OldDiscountExtID, Discount OldDiscount 
 into #t
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID and
       PriceP>0 and 
       PriceN>0 and
       DiscountExtID!=-100 and  // надо проверить не больше ли процент по купону получится, за исключением ручной отмены скидки
       --DiscountCardID=0 and //!!! ЧТО ДЕЛАТЬ С КАРТАМИ ЕСЛИ УДЕ ДАНЫ ПО НИМ СКИДКИ? - Чигрин отменяем и даем если больше процент
       TypeTMC not in (-1,3,6,7)  --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)  
       and TypeTMC<100 --для Универмага Витебск 2016 04 и для других где надо показать отдельно типы товара в зэте и не давать на это скидкинапример 105 - Подарочный сертиф.
       
 order by ID
 
 update #t
 set Discount=isnull(DiscountTypesExt.Percent,0),
     DiscountExtID=isnull(DiscountTypesExt.ID,0),
     Kind=isnull(DiscountTypesExt.Kind,0)
 from #t, 
      DiscountTypesExt
 where DiscountTypesExt.ID>0 and
       DiscountTypesExt.ID=
        (select max(DTE.ID) 
         from DiscountTypesExt DTE, DiscountTypes DT
         where DTE.TMCID=#t.TMCID and
               DTE.ChSum<=@ChSum and
               DTE.OnOff=1 and
                ( (convert(date, convert(varchar(10),@CurrentDateTime,104) ) between 
                   convert(date, convert(varchar(10),DTE.DTOfBegin,104)) and convert(date, convert(varchar(10),DTE.DTOfEnd,104)) )  or
                    (datepart(yy, DTE.DTOfBegin)=1900 and datepart(yy, DTE.DTOfEnd)=1900) ) and
                ( (convert(time,@CurrentDateTime,108) between convert(time, DTE.DTOfBegin,108) and convert(time, DTE.DTOfEnd,108)) or
                  (convert(time, DTE.DTOfBegin,108)=convert(time, DTE.DTOfEnd,108)) ) and
                DT.ID=DTE.DiscountID and
                DT.OnOff=1 and
                DT.IsDiscount=4)
                
                
 update #t
 set Discount=isnull(DiscountTypesExt.Percent,0),
     DiscountExtID=isnull(DiscountTypesExt.ID,0),
     Kind=isnull(DiscountTypesExt.Kind,0)
 from #t, 
      DiscountTypesExt
 where DiscountTypesExt.ID>0 and
       DiscountTypesExt.ID=
        (select max(DTE.ID) 
         from DiscountTypesExt DTE, DiscountTypes DT
         where DTE.GroupOfTMCID=#t.GroupID and
               DTE.GroupOfTMCID!=0 and
               DTE.ChSum<=@ChSum and
               DTE.OnOff=1 and
                ( (convert(date, convert(varchar(10),@CurrentDateTime,104) ) between 
                   convert(date, convert(varchar(10),DTE.DTOfBegin,104)) and convert(date, convert(varchar(10),DTE.DTOfEnd,104)) )  or
                    (datepart(yy, DTE.DTOfBegin)=1900 and datepart(yy, DTE.DTOfEnd)=1900) ) and
                ( (convert(time,@CurrentDateTime,108) between convert(time, DTE.DTOfBegin,108) and convert(time, DTE.DTOfEnd,108)) or
                  (convert(time, DTE.DTOfBegin,108)=convert(time, DTE.DTOfEnd,108)) ) and
                DT.ID=DTE.DiscountID and
                DT.OnOff=1 and
                DT.IsDiscount=4)

 delete #t
 where DiscountExtID=0
 
 --удалим тех у кого изначальная скидка больше купоной
 delete #t
 where OldDiscount>Discount
 
 if (select count(*) from #t)=0
   return 1 

 declare gt cursor  for
 select ID, PriceP, PricePAll, VAT, WareCost, Quantity, CostN, KindRound, DiscountExtID, Discount, Kind
 from #t
 order by ID
        
 
 begin transaction

 if exists(select 1 from CashVoucher where IDD=@CashVoucherID and Status!=0) 
  begin
   rollback transaction raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 open gt
 fetch gt into @gtID,@gtPriceP,@gtPricePAll,@gtVAT, @gtWareCost, @gtQuantity,@gtCostN,@gtKindRound, @gtDiscountExtID, @gtDiscount, @gtKindDiscont
 while @@sqlstatus=0
  begin

   select @TMPCOST=@gtCostN, @gtDiscountSum=0, @gtPriceN=@gtPricePAll
   
   if @Apteka=0   /* для всех */
     begin
      select @gtPricePAll=round((@gtPricePAll*(1-@gtDiscount*0.01)),2)
      exec RulesOfRoundOff 1,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out -- до мин. ед.
      select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2) 
      --select @gtPriceN=round((@gtPricePAll-(@gtWareCost*(1+@WareVAT*0.01)))/(1+@TFS*0.01)/(1+@VAT*0.01)+(@WareCost*(1+@WareVAT*0.01)),2) 
     end 
     else      /* для аптек - Тип скидки   0. Просто скидка на кассе - кассир  1.Процент от наценки  2.Процент от цены с контролем наценки  
                                           3.Процент от цены без контроля наценки 4.Продаем TMCID по цене указанной в поле  Percent */
      begin                                      
        if @gtKindDiscont=1 
            select @gtPricePAll=round( (@gtPriceP-(@gtWareCost*(@gtDiscount*0.01)))*(1+@gtVAT*0.01) ,2)  
        
        if @gtKindDiscont=2 or @gtKindDiscont=3 or @gtKindDiscont=0
            select @gtPricePAll=round((@gtPricePAll*(1-@gtDiscount*0.01)),2)

        if @gtKindDiscont=4 
            begin
             select @gtPricePAll=@gtDiscount          
             select @gtDiscount=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
            end 

        if @gtKindDiscont=2 and @gtWareCost<@gtPriceP-round(@gtPricePAll/(1+@gtVAT*0.01),2)
            begin
              select @gtPricePAll=(@gtPriceP-@gtWareCost)*(1+@gtVAT*0.01)
              if @gtWareCost=0
                select @gtDiscount=0, @gtPricePAll=@gtPriceN --тут розница до скидки
               else 
                select @gtDiscount=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
            end
       
         exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out 
         select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2) 
      end/* конец для аптек*/
 
 if @Apteka=1
    exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,4),@gtCostN out,@RoundOff out,@Result out  
  else
    exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,2),@gtCostN out,@RoundOff out,@Result out     
 
    select @gtDiscountSum=@TMPCOST-@gtCostN
    select @DiscountSum=@DiscountSum+@gtDiscountSum

    update CashVoucherContents
    set PriceN=@gtPriceN,
        PricePAll=@gtPricePAll,
        CostN=@gtCostN,
        RestOfRound=@RoundOff,
        DiscountExtID=@gtDiscountExtID,
        DiscountCardID=0, 
        Discount=@gtDiscount,
        DiscountSum=@gtDiscountSum 
    from CashVoucherContents 
    where CashVoucherID=@CashVoucherID and 
          ID=@gtID
   
      
    fetch gt into @gtID,@gtPriceP,@gtPricePAll,@gtVAT, @gtWareCost, @gtQuantity,@gtCostN,@gtKindRound, @gtDiscountExtID, @gtDiscount, @gtKindDiscont  

  end 
 close gt 

 commit transaction 

 return 1 
end
/
grant execute on CashVoucherContentSetSumDiscou to PUBLIC
/

if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentSetCouponDis') then
   drop procedure CashVoucherContentSetCouponDis
end if
/


create procedure CashVoucherContentSetCouponDis 
(
 @CashVoucherID numeric(10),
 @DiscountCouponID numeric(10),
 @DiscountSum numeric(18,2) out
)
as 
begin

 declare @RoundOff numeric(18,2), @Result int,
         @gtID numeric(10),@gtPriceN numeric(18,2),@gtPriceP numeric(18,2),@gtPricePAll money, @gtVAT numeric(6,2),
         --@gtTFS numeric(6,2),gtWareVAT numeric(6,2),
         @gtWareCost numeric(18,2),@gtQuantity numeric(19,4),@gtCostN money,
         @gtKindRound smallint,@gtDiscountSum numeric(18,2),@TMPCOST numeric(18,2),
         @gtDiscountExtID numeric(10), @gtDiscount smallmoney, @gtKindDiscont smallint,
         @CurrentDateTime datetime,
         @Apteka smallint
   
   
 select @Apteka=1  --!!! тут меняем 0-1 
        
 select @CurrentDateTime=getdate()

 select @DiscountSum=0 

 select ID, TMCID, PriceP, PricePAllFix PricePAll, VAT,--TFS,WareVAT,
        WareCost, Quantity, CostN+DiscountSum as CostN, KindRound, GroupID, DiscountExtID, Discount, convert(smallint,0) Kind,
        DiscountExtID OldDiscountExtID, Discount OldDiscount 
 into #t
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID and
       PriceP>0 and 
       PriceN>0 and
       --Discount=0 and 
       --DiscountSum=0 and
       DiscountExtID!=-100 and  // надо проверить не больше ли процент по купону получится, за исключением ручной отмены скидки
       DiscountCardID=0 and
       TypeTMC not in (-1,3,6,7) --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)  
       and TypeTMC<100 --для Универмага Витебск 2016 04 и для других где надо показать отдельно типы товара в зэте и не давать на это скидкинапример 105 - Подарочный сертиф.
 order by ID
 
 update #t
 set Discount=isnull((select DT.Percent from DiscountTypesExt DT where DT.ID=DiscountTypesExt.ID),0),
     DiscountExtID=isnull(DiscountTypesExt.ID,0),
     Kind=isnull((select DT.Kind from DiscountTypesExt DT where DT.ID=DiscountTypesExt.ID),0)
 from #t, 
      DiscountTypesExt,
      DiscountTypes
 where --#t.DiscountExtID=0 and
       DiscountTypesExt.ID>0 and
       DiscountTypesExt.TMCID=#t.TMCID and
       DiscountTypesExt.DiscountID=@DiscountCouponID and
          --DiscountTypesExt.ChSum<=@ChSum and это условие тут не надо
       DiscountTypesExt.OnOff=1 and
       /*
        ( (convert(date,@CurrentDateTime,104) between convert(date,DiscountTypesExt.DTOfBegin,104) and convert(date,DiscountTypesExt.DTOfEnd,104))  or
          (datepart(yy,DiscountTypesExt.DTOfBegin)=1900 and datepart(yy,DiscountTypesExt.DTOfEnd)=1900) ) and
        ( (convert(time,@CurrentDateTime,108) between convert(time,DiscountTypesExt.DTOfBegin,108) and convert(time,DiscountTypesExt.DTOfEnd,108)) or
          (convert(time,DiscountTypesExt.DTOfBegin,108)=convert(time,DiscountTypesExt.DTOfEnd,108)) ) and */
       ( (convert(date, convert(varchar(10),@CurrentDateTime,104) ) between 
             convert(date, convert(varchar(10),DiscountTypesExt.DTOfBegin,104)) and convert(date, convert(varchar(10),DiscountTypesExt.DTOfEnd,104)) )  or
            (datepart(yy,DiscountTypesExt.DTOfBegin)=1900 and datepart(yy,DiscountTypesExt.DTOfEnd)=1900) ) and
          ( (convert(time,@CurrentDateTime,108) between convert(time,DiscountTypesExt.DTOfBegin,108) and convert(time,DiscountTypesExt.DTOfEnd,108)) or
            (convert(time,DiscountTypesExt.DTOfBegin,108)=convert(time,DiscountTypesExt.DTOfEnd,108)) ) and      
          DiscountTypes.ID=DiscountTypesExt.DiscountID and
          DiscountTypes.OnOff=1 and
          DiscountTypes.IsDiscount=3
 
 update #t
 set Discount=isnull((select DT.Percent from DiscountTypesExt DT where DT.ID=DiscountTypesExt.ID),0),
     DiscountExtID=isnull(DiscountTypesExt.ID,0),
     Kind=isnull((select DT.Kind from DiscountTypesExt DT where DT.ID=DiscountTypesExt.ID),0)
 from #t, 
      DiscountTypesExt,
      DiscountTypes
 where --#t.DiscountExtID=0 and
       DiscountTypesExt.ID>0 and
       DiscountTypesExt.GroupOfTMCID=#t.GroupID and
       DiscountTypesExt.GroupOfTMCID!=0 and
       DiscountTypesExt.DiscountID=@DiscountCouponID and
        --DiscountTypesExt.ChSum<=@ChSum and это условие тут не надо
       DiscountTypesExt.OnOff=1 and
       ( (convert(date, convert(varchar(10),@CurrentDateTime,104) ) between 
             convert(date, convert(varchar(10),DiscountTypesExt.DTOfBegin,104)) and convert(date, convert(varchar(10),DiscountTypesExt.DTOfEnd,104)) )  or
            (datepart(yy,DiscountTypesExt.DTOfBegin)=1900 and datepart(yy,DiscountTypesExt.DTOfEnd)=1900) ) and
          ( (convert(time,@CurrentDateTime,108) between convert(time,DiscountTypesExt.DTOfBegin,108) and convert(time,DiscountTypesExt.DTOfEnd,108)) or
            (convert(time,DiscountTypesExt.DTOfBegin,108)=convert(time,DiscountTypesExt.DTOfEnd,108)) ) and   
       DiscountTypes.ID=DiscountTypesExt.DiscountID and
       DiscountTypes.OnOff=1 and
       DiscountTypes.IsDiscount=3
 
 
 delete #t
 where DiscountExtID=0
 
 --удалим тех у кого изначальная скидка больше купоной
 delete #t
 where OldDiscount>Discount
 
 if (select count(*) from #t)=0
   return 1 

 declare gt cursor  for
 select ID, PriceP, PricePAll, VAT, WareCost, Quantity, CostN, KindRound, DiscountExtID, Discount, Kind
 from #t
 order by ID
        
 
 begin transaction

 if exists(select 1 from CashVoucher where IDD=@CashVoucherID and Status!=0) 
  begin
   rollback transaction raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 open gt
 fetch gt into @gtID,@gtPriceP,@gtPricePAll,@gtVAT, @gtWareCost, @gtQuantity,@gtCostN,@gtKindRound, @gtDiscountExtID, @gtDiscount, @gtKindDiscont
 while @@sqlstatus=0
  begin

   select @TMPCOST=@gtCostN, @gtDiscountSum=0, @gtPriceN=@gtPricePAll
   
  /* для всех пока не переписано возможно не пригодится */
  /*   select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
       exec RulesOfRoundOff 1,@PricePAll,@PricePAll out,@RoundOff out,@Result out  -- до мин. ед.
       select @PriceN=round((@PricePAll-(@WareCost*(1+@WareVAT*0.01)))/(1+@TFS*0.01)/(1+@VAT*0.01)+(@WareCost*(1+@WareVAT*0.01)),2) */

  /* для аптек - Тип скидки 
    0. Просто скидка на кассе - кассир
    1.Процент от наценки
    2.Процент от цены с контролем наценки
    3.Процент от цены без контроля наценки
    4.Продаем TMCID по цене указанной в поле  Percent */
   if @gtKindDiscont=1 
      select @gtPricePAll=round( (@gtPriceP-(@gtWareCost*(@gtDiscount*0.01)))*(1+@gtVAT*0.01) ,2)  

   if @gtKindDiscont=2 or @gtKindDiscont=3 or @gtKindDiscont=0
      select @gtPricePAll=round((@gtPricePAll*(1-@gtDiscount*0.01)),2)

   if @gtKindDiscont=4 
      begin
       select @gtPricePAll=@gtDiscount          
       select @gtDiscount=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
      end 

   if @gtKindDiscont=2 and @gtWareCost<@gtPriceP-round(@gtPricePAll/(1+@gtVAT*0.01),2)
       begin
        select @gtPricePAll=(@gtPriceP-@gtWareCost)*(1+@gtVAT*0.01)
        if @gtWareCost=0
          select @gtDiscount=0, @gtPricePAll=@gtPriceN --тут розница до скидки
         else 
          select @gtDiscount=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
       end
       
     exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out 
     select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2) 
    /* конец для аптек*/
 
 if @Apteka=1
    exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,4),@gtCostN out,@RoundOff out,@Result out  
  else
    exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,2),@gtCostN out,@RoundOff out,@Result out     
 
    select @gtDiscountSum=@TMPCOST-@gtCostN
    select @DiscountSum=@DiscountSum+@gtDiscountSum

    update CashVoucherContents
    set PriceN=@gtPriceN,
        PricePAll=@gtPricePAll,
        CostN=@gtCostN,
        RestOfRound=@RoundOff,
        DiscountExtID=@gtDiscountExtID,
        Discount=@gtDiscount,
        DiscountSum=@gtDiscountSum 
    from CashVoucherContents 
    where CashVoucherID=@CashVoucherID and 
          ID=@gtID
   
      
    fetch gt into @gtID,@gtPriceP,@gtPricePAll,@gtVAT, @gtWareCost, @gtQuantity,@gtCostN,@gtKindRound, @gtDiscountExtID, @gtDiscount, @gtKindDiscont  

  end 
 close gt 

 commit transaction 

 return 1 
end
/
grant execute on CashVoucherContentSetCouponDis to PUBLIC
/

if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentUpdating') then
   drop procedure CashVoucherContentUpdating
end if
/


create procedure CashVoucherContentUpdating 
(@CashVoucherID numeric(10),@ID numeric(10),@PriceN numeric(18,2),@PriceP numeric(18,2),@PricePAll numeric(18,2),
 @Quantity numeric(19,4),@CostN numeric(18,2),@KindRound smallint,@WareHouseID numeric(10),
 @DiscountSum numeric(18,2) out,@Discount smallmoney out)
as
begin
 declare @RoundOff numeric(18,2),@Result int
 declare @DateC datetime,@TMPCOST numeric(18,2),
         @IDDTMC numeric(10),@GroupID numeric(10),@LocWHID numeric(10),@TMCID numeric(10),
         @DiscountExtID numeric(10),@PricePAllFix numeric(18,2), @TypeTMC smallint,
         @VAT numeric(6,2),@TFS numeric(6,2),@WareCost numeric(18,2),@WareVAT numeric(6,2),
         --только для аптек !!!
         @KindDiscont  smallint, @DateLife datetime, @OldQuantity numeric(19,4), @IsRecourse smallint,
         @Apteka smallint, @DiscountCardID numeric(10)
   
   
 select @Apteka=1  --!!! тут меняем 0-1 
         

 if @ID<0 
  select @IsRecourse=1, @ID=abs(@ID)
   else select @IsRecourse=0


 if @Discount is null
  select @Discount=0  

 select @DateC=getdate()
 
 select @LocWHID=LocWareHouseID from CashVoucher 
 where IDD=@CashVoucherID

 select @IDDTMC=IDDTMC,@GroupID=GroupID,@TMCID=TMCID,@PricePAllFix=PricePAllFix, 
        @Discount=case when @Discount>0 then @Discount else Discount end,-- // 2014 06 для абсолютной скидки кассы
        @DiscountExtID=DiscountExtID, --// 2014 09 надо анализировать была ли скидка так как при изменении количества мы ниже ее можем потерять
        @VAT=VAT,@TFS=TFS,@WareCost=WareCost,@WareVAT=WareVAT, @TypeTMC=TypeTMC
         --только для аптек !!!
        ,@DateLife=convert(datetime,substring(MeasureName,1,charindex(char(160),MeasureName)-1),104)
        ,@OldQuantity=Quantity, @DiscountCardID=DiscountCardID
        
 from CashVoucherContents
 where CashVoucherID=@CashVoucherID and ID=@ID
 
 if @TypeTMC in (-1,3,6,7) --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)  
  begin  
   select @Discount=0, @DiscountExtID=0
   goto done
  end 

 if @Discount=0 or -- новое 2014 06 для абсолютной скидки кассы
    --@DiscountExtID!=0 -- 2014 09 надо анализировать была ли скидка так как при изменении количества мы ее можем потерять
    (@DiscountExtID!=0 and @DiscountExtID!=-100) --2019 01 иначе теряем скидку ручную
  begin
   if @WareHouseID=0
    exec DiscountPercent @IDDTMC,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out
   else  
   if @Apteka=0
    begin
     exec DiscountPercent @TMCID,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out  
     if @DiscountExtID=0 //ищем скидки от цены товара
        exec DiscountPercent -100,-100, @DateC, @LocWHID, @PricePAllFix, @Discount out, @DiscountExtID out 
    end 
    else     
    if @Apteka=1 --для аптек своя процедура !!!
     begin
      exec DiscountPercentAP @TMCID, @GroupID, @DateC, @LocWHID, @Quantity-@OldQuantity, @DateLife, @CashVoucherID, @Discount out, @DiscountExtID out
      if @DiscountExtID=0
        exec DiscountPercent @TMCID,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out  
      select @KindDiscont=isnull(min(Kind),0) from DiscountTypesExt where ID=@DiscountExtID
     end 
  end 
   else select /*case when @DiscountExtID!=100 then @DiscountExtID=0 else */ @DiscountExtID=0, @KindDiscont=0  
   
 if @Apteka=1 and @DiscountCardID!=0  --для аптек  !!!   
  begin 

    select @KindDiscont=case  
                         when DiscountID=1 then 2
                         when DiscountID=2 then 1
                         when DiscountID=3 then 3
                         when DiscountID=4 then 2
                         when DiscountID=-4 then 3
                         when DiscountID=5 then 2
                         when DiscountID=6 then 3
                          else 0
                        end  
    from DiscountCards
    where ID=@DiscountCardID
   
    if @@rowcount=0
      select @KindDiscont=2 // карты Евроторга для ижици это карта эл. рецепта
      
//@KindDiscont карточный 
// 1 - скидка от цены социальная карта только бел. товар - без превышения торг. нац. (ТН)
// 2 - скидка от розничной наценки без превышения
// 3 - скидка от розничной цены с превышением ТН
// 4 - скидка баллами  стандартная скидка пропорционально списываем баллы в пределах торг. наценки - начисление баллов от наценки
//-4 - скидка баллами  стандартная скидка пропорционально списываем баллы в пределах торг. наценки - начисление баллов от розничной цены
// 5 - детская карта   Скидка от розничной цены в пределах торговой надбавки - для тестов 485937399739
// 6 - проект Эконом карта   Скидка от розничной цены в пределах торговой надбавки от РОЦ
//-4 - c 2018 скидка баллами  стандартная скидка пропорционально списываем баллы в пределах 70% от розничной цены - начисление баллов от розничной цены
// 7   карты Евроторга. Условия ЛС, ИМТ, ИМН – 1% ИД группы(1,5,6) остальное 5 процентов в пределах наценки
      //для ижици это карта эл. рецепта
    
    
  end
   
done:

 if @PricePAllFix!=0 select @PricePAll=@PricePAllFix,@PriceN=@PriceP
 /* для нулевых цен - режим кассы установка PricePAllFix - для правильной печати чека */
 if @PricePAllFix=0 select @PricePAllFix=@PricePAll 
 /*проставка цен при режиме просто кассы для получения скидок 2012 09 для ясеня*/
 if @PriceN=0 select @PriceN=@PricePAll
 if @PriceP=0 select @PriceP=@PricePAll


 if @Discount>0 
 begin
  /* для всех */
 if @Apteka=0
  begin  
   exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,2),@TMPCOST out,@RoundOff out,@Result out
   select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
   exec RulesOfRoundOff 1,@PricePAll,@PricePAll out,@RoundOff out,@Result out  -- до мин. ед.
   select @PriceN=round((@PricePAll-(@WareCost*(1+@WareVAT*0.01)))/(1+@TFS*0.01)/(1+@VAT*0.01)+(@WareCost*(1+@WareVAT*0.01)),2)
  end
   else /* для аптек */    
    begin
        /* Тип скидки 
        0. Просто скидка на кассе - кассир
        1.Процент от наценки
        2.Процент от цены с контролем наценки
        3.Процент от цены без контроля наценки
        4.Продаем TMCID по цене указанной в поле  Percent */
      exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@TMPCOST out,@RoundOff out,@Result out
      if @KindDiscont=1 
        select @PricePAll=round( (@PriceP-(@WareCost*(@Discount*0.01)))*(1+@VAT*0.01) ,2)  
      if @KindDiscont=2 or @KindDiscont=3 or @KindDiscont=0
        select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
      if @KindDiscont=4 
        begin
         if @Discount<@PricePAll
          begin
           select @PricePAll=@Discount          
           select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
          end
          else  
           select  @Discount=0
        end 

       if @KindDiscont=2 and @WareCost<@PriceP-round(@PricePAll/(1+@VAT*0.01),2)
        begin
         select @PricePAll=(@PriceP-@WareCost)*(1+@VAT*0.01)
         if @WareCost=0
           select @Discount=0, @PricePAll=@PricePAllFix
          else 
           select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
        end
       
       exec RulesOfRoundOff @KindRound,@PricePAll,@PricePAll out,@RoundOff out,@Result out 
       select @PriceN=round(@PricePAll/(1+@VAT*0.01),2) 
    end /* конец для аптек*/
 end
 
 
 if @Apteka=1
  exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@CostN out,@RoundOff out,@Result out  
 else
  exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out 
 
/* if @Discount=0  было до верхнего куска
  exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@CostN out,@RoundOff out,@Result out 
 else
  exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,4),@CostN out,@RoundOff out,@Result out   */
 

 if @Discount>0 select @DiscountSum=@TMPCOST-@CostN
  else select @DiscountSum=0

 begin transaction
 if exists(select 1 from CashVoucher (index PK_CASHVOUCHER) where IDD=@CashVoucherID and Status!=0) 
  begin
   rollback transaction raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 if (select PriceP from CashVoucherContents where CashVoucherID=@CashVoucherID and ID=@ID)=0 
  begin
  update CashVoucherContents
  set PriceN=@PriceN,
      PriceP=@PriceP,
      PricePAll=@PricePAll,
      Quantity=@Quantity,
      RestOfRound=@RoundOff,
      CostN=@CostN,
      Discount=@Discount,
      DiscountExtID=case when @Discount!=0 and @DiscountExtID=0 and DiscountCardID=0 then -100 else @DiscountExtID end, --//201805 для ясеня скидка дана кассиром ипередачи в бэк этой скидки
      DiscountSum=@DiscountSum,
      PricePAllFix=@PricePAllFix
  from CashVoucherContents 
  where CashVoucherID=@CashVoucherID and ID=@ID
  end
  else 
   begin
    update CashVoucherContents
    set PriceN=@PriceN, --//2014 06 для абсолютной скидки кассы
        PricePAll=@PricePAll,--//2014 06 для абсолютной скидки кассы
        Quantity=@Quantity,
        RestOfRound=@RoundOff,
        CostN=@CostN,
        Discount=@Discount,
        DiscountExtID=case when @Discount!=0 and @DiscountExtID=0 and DiscountCardID=0 then -100 else @DiscountExtID end, --//201805 для ясеня скидка дана кассиром ипередачи в бэк этой скидки
        DiscountSum=@DiscountSum,
        PricePAllFix=@PricePAllFix
    from CashVoucherContents 
    where CashVoucherID=@CashVoucherID and ID=@ID
   end
 commit transaction 
    
 --только для аптек !!!
 if @Apteka=1
  if @IsRecourse=0 exec DiscountChecktAP  @CashVoucherID, @ID
 
 return 1 
end
/
grant execute on CashVoucherContentUpdating to PUBLIC
/

if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentInserting') then
   drop procedure CashVoucherContentInserting
end if
/


create procedure CashVoucherContentInserting 
(@CashVoucherID numeric(10),@TMCID numeric(10),@BarCode numeric(13),@Name varchar(250),@MeasureName varchar(60),
 @PriceN numeric(18,2), @PriceP numeric(18,2),@PricePAll numeric(18,2),@VAT numeric(6,2),@TFS numeric(6,2),
 @WareCost numeric(18,2),@WareVAT numeric(6,2),@TypeTMC smallint,
 @DiscountExtID numeric(10),@DiscountCardID numeric(10),@Quantity numeric(19,4),@CostN numeric(18,2),
 @KindRound smallint,@IDDTMC numeric(10),@LocWHID numeric(10),@WareHouseID numeric(10),@GroupID numeric(10),
 @ID numeric(10) out,@Discount smallmoney out,@DiscountSum numeric(18,2) out)
as 
begin 
 declare @RoundOff numeric(18,2),@Result int, @PricePAllFix numeric(18,2),
         @DateC datetime,@TMPCOST numeric(18,2),
         @KindDiscont  smallint, @DateLife datetime,
         @Apteka smallint
    
 select @Apteka=1  --!!! тут меняем 0-1 
 
 select @PricePAllFix=@PricePAll

 select @ID=isnull(max(ID),0)+1 from CashVoucherContents where CashVoucherID=@CashVoucherID

 --определить есть ли скидка на товар
 if @TypeTMC not in (-1,3,6,7) -- 2014 11 если товар подлежит скидке
  begin 
   select @DateC=getdate()
   if @WareHouseID=0
    exec DiscountPercent @IDDTMC,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out
   else 
   if @Apteka=0 
    begin
     exec DiscountPercent @TMCID,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out
     if @DiscountExtID=0 //ищем скидки от цены товара
        exec DiscountPercent -100,-100, @DateC, @LocWHID, @PricePAll, @Discount out, @DiscountExtID out 
    end 
    else 
    if @Apteka=1     --для аптек своя процедура !!!
     begin
      select @DateLife=convert(datetime,substring(@MeasureName,1,charindex(char(160),@MeasureName)-1),104)
      exec DiscountPercentAP @TMCID, @GroupID, @DateC, @LocWHID, @Quantity, @DateLife, @CashVoucherID, @Discount out, @DiscountExtID out
      select @KindDiscont=Kind from DiscountTypesExt where ID=@DiscountExtID
     end 
  end
   else select @Discount=0, @DiscountExtID=0
    
 --

 if @Discount>0 
 begin
  if @Apteka=0 /* для всех */
   begin
    exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,2),@TMPCOST out,@RoundOff out,@Result out
    select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
    exec RulesOfRoundOff 1,@PricePAll,@PricePAll out,@RoundOff out,@Result out /*до мин ден ед.*/
    select @PriceN=round((@PricePAll-(@WareCost*(1+@WareVAT*0.01)))/(1+@TFS*0.01)/(1+@VAT*0.01)+(@WareCost*(1+@WareVAT*0.01)),2)
   end
   else  /* для аптек */    
   begin
   /* Тип скидки 
    0. Просто скидка на кассе - кассир
    1.Процент от наценки
    2.Процент от цены с контролем наценки
    3.Процент от цены без контроля наценки
    4.Продаем TMCID по цене указанной в поле  Percent */
    exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@TMPCOST out,@RoundOff out,@Result out
    if @KindDiscont=1 
      select @PricePAll=round( (@PriceP-(@WareCost*(@Discount*0.01)))*(1+@VAT*0.01) ,2)  
    if @KindDiscont=2 or @KindDiscont=3 or @KindDiscont=0
      select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
    if @KindDiscont=4 
      begin
       if @Discount<@PricePAll
         begin
          select @PricePAll=@Discount          
          select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
         end
         else  
          select @Discount=0 
      end 

      if @KindDiscont=2 and @WareCost<@PriceP-round(@PricePAll/(1+@VAT*0.01),2)
       begin
        select @PricePAll=(@PriceP-@WareCost)*(1+@VAT*0.01)
        if @WareCost=0
          select @Discount=0, @PricePAll=@PricePAllFix
         else 
          select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
       end
     exec RulesOfRoundOff @KindRound,@PricePAll,@PricePAll out,@RoundOff out,@Result out 
     select @PriceN=round(@PricePAll/(1+@VAT*0.01),2)
   end /* конец для аптек*/
 end
   
 if @Apteka=1
   exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@CostN out,@RoundOff out,@Result out  
  else
   exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out  

/* if @Discount=0  
  exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out  
 else 
  exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out   до минимальной денежной единицы по мат. правилам*/

 
 if @Discount>0 select @DiscountSum=@TMPCOST-@CostN
  else select @DiscountSum=0 
begin transaction
 insert into CashVoucherContents(CashVoucherID,ID,TMCID,BarCode,Name,MeasureName,PriceN,PriceP,PricePAll,VAT,TFS,WareCost,WareVAT,TypeTMC,
                       DiscountExtID,DiscountCardID,Discount,DiscountSum,Quantity,CostN,KindRound,RestOfRound, GroupID, IDDTMC, PricePAllFix)
 values (@CashVoucherID,@ID,@TMCID,@BarCode,@Name,@MeasureName,@PriceN,@PriceP,@PricePAll,@VAT,@TFS,
         @WareCost,@WareVAT,@TypeTMC,@DiscountExtID,@DiscountCardID,@Discount,@DiscountSum,@Quantity,@CostN,@KindRound,@RoundOff,@GroupID,@IDDTMC,@PricePAllFix) 

commit transaction 
         
 --только для аптек !!!
 if @Apteka=1 
  exec DiscountChecktAP  @CashVoucherID, @ID          
          
 return 1 
end
/
grant execute on CashVoucherContentInserting to PUBLIC
/

if exists(select 1 from sys.sysprocedure where proc_name = 'DiscountChPosPercent') then
   drop procedure DiscountChPosPercent
end if
/


create procedure DiscountChPosPercent
(
 @CashVoucherID numeric(10),
 @CurrentDateTime varchar(20),
 @DiscountSum money out
) 
as
begin
 
 declare @DateCur datetime, @DiscountTypesID numeric(10)
 declare @RoundOff numeric(18,2), @Result int,
         @gtID numeric(10),@gtPriceN numeric(18,2),@gtPricePAll numeric(18,2),@gtVAT numeric(6,2),@gtTFS numeric(6,2),
         @gtWareCost numeric(18,2),@gtWareVAT numeric(6,2),@gtQuantity numeric(19,4),@gtCostN numeric(18,2),
         @gtKindRound smallint, @gtPercent smallmoney, @gtMaxSumm money,
         @TMPCOST numeric(18,2), @gtDTEID numeric(10),
         @Apteka smallint
   
   
 select @Apteka=1  --!!! тут меняем 0-1  для аптек

 if exists(select 1 from CashVoucher where IDD=@CashVoucherID and Status!=0) 
  begin
   raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 select @DateCur=convert(datetime,@CurrentDateTime)
 
 select @DiscountSum=0       

 --поиск в локальных таблицах сначала
 select @DiscountTypesID=isnull(min(DiscountTypes.ID),0)
 from DiscountTypesExt,
      DiscountTypes
 where DiscountTypesExt.ID<0 and
       DiscountTypesExt.TMCID<0 and
       DiscountTypesExt.GroupOfTMCID=0 and
       DiscountTypesExt.OnOff=1 and 
       ( (convert(date, convert(varchar(10),@DateCur,104) ) between 
          convert(date, convert(varchar(10),DiscountTypesExt.DTOfBegin,104)) and convert(date, convert(varchar(10),DiscountTypesExt.DTOfEnd,104)) )  or
         (datepart(yy,DiscountTypesExt.DTOfBegin)=1900 and datepart(yy,DiscountTypesExt.DTOfEnd)=1900) ) and
       ( (convert(time,@DateCur,108) between convert(time,DiscountTypesExt.DTOfBegin,108) and convert(time,DiscountTypesExt.DTOfEnd,108)) or
         (convert(time,DiscountTypesExt.DTOfBegin,108)=convert(time,DiscountTypesExt.DTOfEnd,108)) ) and
       DiscountTypes.ID=DiscountTypesExt.DiscountID and
       DiscountTypes.OnOff=1   

 if @DiscountTypesID=0
 
 select @DiscountTypesID=isnull(max(DiscountTypes.ID),0)
 from DiscountTypesExt,
      DiscountTypes
 where DiscountTypesExt.ID>0 and
       DiscountTypesExt.TMCID<0 and
       DiscountTypesExt.GroupOfTMCID=0 and
       DiscountTypesExt.OnOff=1 and 
       ( (convert(date, convert(varchar(10),@DateCur,104) ) between 
          convert(date, convert(varchar(10),DiscountTypesExt.DTOfBegin,104)) and convert(date, convert(varchar(10),DiscountTypesExt.DTOfEnd,104)) )  or
         (datepart(yy,DiscountTypesExt.DTOfBegin)=1900 and datepart(yy,DiscountTypesExt.DTOfEnd)=1900) ) and
       ( (convert(time,@DateCur,108) between convert(time,DiscountTypesExt.DTOfBegin,108) and convert(time,DiscountTypesExt.DTOfEnd,108)) or
         (convert(time,DiscountTypesExt.DTOfBegin,108)=convert(time,DiscountTypesExt.DTOfEnd,108)) ) and
       DiscountTypes.ID=DiscountTypesExt.DiscountID and
       DiscountTypes.OnOff=1 
       
 if @DiscountTypesID!=0
  begin
  
   --select number(*) as PosNumber,ID, PriceN, PricePAll, VAT, TFS, WareCost, WareVAT, Quantity, CostN, KindRound, Discount as Percent,  
   -- 2019 03 ntgthm отменяем скидку на позицию если была
   select number(*) as PosNumber,ID, PriceP as PriceN, PricePAllFix as PricePAll, VAT, TFS, WareCost, WareVAT, Quantity, CostN+DiscountSum as CostN, KindRound, Discount as Percent, 
          convert(money,0) as MaxSumm, convert(numeric(10),0) as DTEID
   into #t
   from CashVoucherContents
   where CashVoucherID=@CashVoucherID and
         PriceP>0 and 
         PriceN>0 and
         DiscountCardID=0 and
         (
          (Discount=0 and 
           DiscountSum=0 and
           DiscountExtID=0
           ) or DiscountExtID in (select DTE.ID from DiscountTypesExt DTE where DTE.DiscountID=@DiscountTypesID)
         ) and
         TypeTMC not in (-1,3,6,7) --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)
         --and GroupID=546 --новое для Кирмаша ограничение по группе(производителю) на кого только действует скидка
         and (@Apteka=0 or GroupID in (2,3,4)) --для аптек  ограничение по группам ТНП БАД КОСМЕТИКА
   order by CostN desc
   
   update #t
     set #t.Percent=DTE.Percent,
         #t.MaxSumm=ChSum,
         #t.DTEID=DTE.ID
   from #t, DiscountTypesExt DTE
   where DTE.DiscountID=@DiscountTypesID and
         DTE.TMCID<0 and  
         DTE.OnOff=1 and
         #t.PosNumber=abs(DTE.TMCID)   

   /**** распределить пропорционально по товарам для тех кому так надо - один процент(средний) для всех товаров  заоменчено должно быть*/ 
 /*  declare @SumDiscount money, @SumTotal money, @avgPercent smallmoney
   select @SumDiscount=sum(#t.PricePAll*Quantity/100*#t.Percent),
          @SumTotal=sum(#t.CostN)
   from #t
   
   select @avgPercent=@SumDiscount/(@SumTotal/100)
           
   update #t
     set #t.Percent=@avgPercent
   from #t
   */      
   /*********/            
   
   
   declare gt cursor  for
   select ID, PriceN, PricePAll, VAT, TFS, WareCost, WareVAT, Quantity, CostN, KindRound, Percent, MaxSumm, DTEID
   from #t
   where Percent!=0
   order by ID
   
   begin transaction

    open gt
    fetch gt into @gtID, @gtPriceN, @gtPricePAll, @gtVAT, @gtTFS, @gtWareCost, @gtWareVAT, @gtQuantity, @gtCostN,@gtKindRound, @gtPercent, @gtMaxSumm, @gtDTEID
    while @@sqlstatus=0
     begin

      select @TMPCOST=@gtCostN

      select @gtPricePAll=round((@gtPricePAll*(1-@gtPercent*0.01)),2)
      
      exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out
      
      if @gtMaxSumm>0 and @gtPricePAll>@gtMaxSumm
        select @gtPricePAll=@gtMaxSumm

      --определяем  цену без налогов
      if @Apteka=1 
        select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2) 
       else 
        select @gtPriceN=round((@gtPricePAll-(@gtWareCost*(1+@gtWareVAT*0.01)))/(1+@gtTFS*0.01)/(1+@gtVAT*0.01)+(@gtWareCost*(1+@gtWareVAT*0.01)),2)

      /* до минимальной денежной единицы по мат. правилам*/
      exec RulesOfRoundOff 10,Round(@gtPricePAll*@gtQuantity,2),@gtCostN out,@RoundOff out,@Result out

      select @DiscountSum=@DiscountSum+(@TMPCOST-@gtCostN)

      update CashVoucherContents
        set PriceN=@gtPriceN,
            PricePAll=@gtPricePAll,
            CostN=@gtCostN,
            RestOfRound=@RoundOff,
            DiscountExtID=@gtDTEID,
            --//DiscountCardID=@DiscountCardID,
            Discount=@gtPercent,
            DiscountSum=(@TMPCOST-@gtCostN) 
      from CashVoucherContents
      where CashVoucherID=@CashVoucherID and ID=@gtID
   
      fetch gt into @gtID, @gtPriceN, @gtPricePAll, @gtVAT, @gtTFS, @gtWareCost, @gtWareVAT, @gtQuantity, @gtCostN,@gtKindRound, @gtPercent, @gtMaxSumm, @gtDTEID
     end 
    close gt 

    --//проставляем Ид скидки (позиции) для тех у кого скидка равна 0
    update CashVoucherContents
     set DiscountExtID=#t.DTEID
    from  #t, CashVoucherContents, 
    where #t.Percent=0 and
          #t.DTEID!=0 and 
          CashVoucherContents.CashVoucherID=@CashVoucherID and
          CashVoucherContents.ID=#t.ID            

    commit transaction 
  
  end --//if @DiscountTypesID!=0     
       
       
 return 1
end
/
grant execute on DiscountChPosPercent to PUBLIC
/


if exists(select 1 from sys.sysprocedure where proc_name = 'CashVoucherContentInserting') then
   drop procedure CashVoucherContentInserting
end if
/


create procedure CashVoucherContentInserting 
(@CashVoucherID numeric(10),@TMCID numeric(10),@BarCode numeric(13),@Name varchar(250),@MeasureName varchar(60),
 @PriceN numeric(18,2), @PriceP numeric(18,2),@PricePAll numeric(18,2),@VAT numeric(6,2),@TFS numeric(6,2),
 @WareCost numeric(18,2),@WareVAT numeric(6,2),@TypeTMC smallint,
 @DiscountExtID numeric(10),@DiscountCardID numeric(10),@Quantity numeric(19,4),@CostN numeric(18,2),
 @KindRound smallint,@IDDTMC numeric(10),@LocWHID numeric(10),@WareHouseID numeric(10),@GroupID numeric(10),
 @ID numeric(10) out,@Discount smallmoney out,@DiscountSum numeric(18,2) out)
as 
begin 
 declare @RoundOff numeric(18,2),@Result int, @PricePAllFix numeric(18,2),
         @DateC datetime,@TMPCOST numeric(18,2),
         @KindDiscont  smallint, @DateLife datetime,
         @Apteka smallint
    
 select @Apteka=1  --!!! тут меняем 0-1 
 
 select @PricePAllFix=@PricePAll

 select @ID=isnull(max(ID),0)+1 from CashVoucherContents where CashVoucherID=@CashVoucherID
 
 --2020 04 продажв по фикс. цене аптека (вариант со скидкой. другие скидки не действуют) 7
 if @Apteka=1 and @DiscountExtID=-100
  begin
   select @KindDiscont=4 --продаем по цене указанной в параметре @Discount 
   goto done
  end 


 --определить есть ли скидка на товар
 if @TypeTMC not in (-1,3,6,7) -- 2014 11 если товар подлежит скидке
  begin 
   select @DateC=getdate()
   if @WareHouseID=0
    exec DiscountPercent @IDDTMC,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out
   else 
   if @Apteka=0 
    begin
     exec DiscountPercent @TMCID,@GroupID,@DateC,@LocWHID,@Quantity,@Discount out, @DiscountExtID out
     if @DiscountExtID=0 //ищем скидки от цены товара
        exec DiscountPercent -100,-100, @DateC, @LocWHID, @PricePAll, @Discount out, @DiscountExtID out 
    end 
    else 
    if @Apteka=1     --для аптек своя процедура !!!
     begin
      select @DateLife=convert(datetime,substring(@MeasureName,1,charindex(char(160),@MeasureName)-1),104)
      exec DiscountPercentAP @TMCID, @GroupID, @DateC, @LocWHID, @Quantity, @DateLife, @CashVoucherID, @Discount out, @DiscountExtID out
      select @KindDiscont=Kind from DiscountTypesExt where ID=@DiscountExtID
     end 
  end
   else select @Discount=0, @DiscountExtID=0
    
done:

if @Discount>0 
 begin
  if @Apteka=0 /* для всех */
   begin
    exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,2),@TMPCOST out,@RoundOff out,@Result out
    select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
    exec RulesOfRoundOff 1,@PricePAll,@PricePAll out,@RoundOff out,@Result out /*до мин ден ед.*/
    select @PriceN=round((@PricePAll-(@WareCost*(1+@WareVAT*0.01)))/(1+@TFS*0.01)/(1+@VAT*0.01)+(@WareCost*(1+@WareVAT*0.01)),2)
   end
   else  /* для аптек */    
   begin
   /* Тип скидки 
    0. Просто скидка на кассе - кассир
    1.Процент от наценки
    2.Процент от цены с контролем наценки
    3.Процент от цены без контроля наценки
    4.Продаем TMCID по цене указанной в поле процент скидки */
    exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@TMPCOST out,@RoundOff out,@Result out
    if @KindDiscont=1 
      select @PricePAll=round( (@PriceP-(@WareCost*(@Discount*0.01)))*(1+@VAT*0.01) ,2)  
    if @KindDiscont=2 or @KindDiscont=3 or @KindDiscont=0
      select @PricePAll=round((@PricePAll*(1-@Discount*0.01)),2)
    if @KindDiscont=4 
      begin
       if @Discount<@PricePAll
         begin
          select @PricePAll=@Discount          
          select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
         end
         else  
          select @Discount=0 
      end 

      if @KindDiscont=2 and @WareCost<@PriceP-round(@PricePAll/(1+@VAT*0.01),2)
       begin
        select @PricePAll=(@PriceP-@WareCost)*(1+@VAT*0.01)
        if @WareCost=0
          select @Discount=0, @PricePAll=@PricePAllFix
         else 
          select @Discount=round(100-(@PricePAll/(@TMPCOST/@Quantity))*100,2)
       end
     exec RulesOfRoundOff @KindRound,@PricePAll,@PricePAll out,@RoundOff out,@Result out 
     select @PriceN=round(@PricePAll/(1+@VAT*0.01),2)
   end /* конец для аптек*/
 end
   
 if @Apteka=1
   exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,4),@CostN out,@RoundOff out,@Result out  
  else
   exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out  

/* if @Discount=0  
  exec RulesOfRoundOff @KindRound,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out  
 else 
  exec RulesOfRoundOff 10,Round(@PricePAll*@Quantity,2),@CostN out,@RoundOff out,@Result out   до минимальной денежной единицы по мат. правилам*/

 
 if @Discount>0 select @DiscountSum=@TMPCOST-@CostN
  else select @DiscountSum=0 
begin transaction
 insert into CashVoucherContents(CashVoucherID,ID,TMCID,BarCode,Name,MeasureName,PriceN,PriceP,PricePAll,VAT,TFS,WareCost,WareVAT,TypeTMC,
                       DiscountExtID,DiscountCardID,Discount,DiscountSum,Quantity,CostN,KindRound,RestOfRound, GroupID, IDDTMC, PricePAllFix)
 values (@CashVoucherID,@ID,@TMCID,@BarCode,@Name,@MeasureName,@PriceN,@PriceP,@PricePAll,@VAT,@TFS,
         @WareCost,@WareVAT,@TypeTMC,@DiscountExtID,@DiscountCardID,@Discount,@DiscountSum,@Quantity,@CostN,@KindRound,@RoundOff,@GroupID,@IDDTMC,@PricePAllFix) 

commit transaction 
         
 --только для аптек !!!
 if @Apteka=1 
  exec DiscountChecktAP  @CashVoucherID, @ID          
          
 return 1 
end
/
grant execute on CashVoucherContentInserting to PUBLIC
/
