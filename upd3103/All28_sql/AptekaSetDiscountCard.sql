if exists(select 1 from sys.sysprocedure where proc_name = 'AptekaSetDiscountCard') then
   drop procedure AptekaSetDiscountCard
end if
/


create procedure AptekaSetDiscountCard 
(
 @CashVoucherID numeric(10),
 @DiscountCardID numeric(10),
 @Discount smallmoney,
 @DiscountSum numeric(18,2) out  //тут на входе кол-во списываемых баллов
)
as
begin
 declare //@Discount smallmoney,
         @Percent  smallmoney,
         @RoundOff numeric(18,2), @Result int,
         @CardPercent  smallmoney,
         @gtID numeric(10),
         @gtPriceN numeric(18,2),@gtPriceP numeric(18,2),
         @gtPricePAll numeric(18,2),@gtVAT numeric(6,2),
         @gtTFS numeric(6,2), 
         @gtWareCost numeric(18,2),@gtWareVAT numeric(6,2),@gtQuantity numeric(19,4),@gtCostN numeric(18,2),
         @gtKindRound smallint, @gtDiscountSum numeric(18,2),@TMPCOST numeric(18,2),
         @KindDiscont  smallint,
         @CheckSum money,
         @PosNumber int
         --,@CurDate datetime

 select @KindDiscont=abs(DiscountID), //типы 4 и -4 работают по одним правилам
        //@Discount=convert(smallmoney,Comments), вроде как пока общее кол-во балов нам не надо 2018 10
        @CardPercent=Percent 
 from DiscountCards
 where ID=@DiscountCardID
 
 if @@rowcount=0
  select @KindDiscont=7, // карты Евроторга для ижици это карта эл. рецепта
         @CardPercent=@Discount 
  
//@KindDiscont 
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
// 8  купоны мастеркар скидка 10 рублей без конролей если сумма покупки меньше - цена товаров 1 копейка
      
 select ID, PriceN, PriceP, PricePAllFix as PricePAll, VAT, GroupID as TFS, WareCost, WareVAT, Quantity, CostN, KindRound , DiscountSum
 into #t
 from CashVoucherContents (index Voucher_idx)
 where CashVoucherID=@CashVoucherID and
       PriceP>0 and 
       PriceN>0 and
       DiscountExtID=0 and
       ( (Discount=0 and DiscountSum=0 and DiscountCardID=0) or @KindDiscont=6) and 
       --TypeTMC!=3 and
       TypeTMC not in (-1,3,6,7) and --не давать скидки на прочие доплаты которые введены как услуги + фикс цены +под.серт.+ авансы(ном.под.серт)  
       ( (WareVAT<0 and GroupID=1)  or @KindDiscont!=1) and
       ( @KindDiscont!=5 or (select count(*) from DiscountAllowedWareHouses where DiscountID=5 and WareHouseID=CashVoucherContents.TMCID and IsAllowed=1)!=0 )
       

 order by ID
 
 select @Result=@@rowcount
 if @Result=0
  begin
   select @DiscountSum=0
   return 1 
  end
  
 select @CheckSum=0 
 
 select @CheckSum=sum(CostN) 
 from #t
 
 if @KindDiscont=4  //считаем процент скидки от суммы переданного бонуса
  select @CardPercent=round( (@DiscountSum/100)/(@CheckSum/100), 2)


 if @KindDiscont=8  //считаем процент скидки от суммы переданного бонуса в 10 рублей 
  begin
    //select @CardPercent=round( (@DiscountSum/100)/((select sum(CostN) from #t)/100), 2)
    if @CheckSum>10
     select @CardPercent=round(10/@CheckSum*100, 2)
    else 
     select @CardPercent=99.99
  end  

 select @CheckSum=0
 
 if @KindDiscont=6 
  begin
   --select @CheckSum=isnull(sum(CostN),0) from CashVoucherContents where CashVoucherID=@CashVoucherID 
   --select @PosNumber=count(ID)+1 from CashVoucherContents where CashVoucherID=@CashVoucherID and DiscountCardID=@DiscountCardID
   select @CheckSum=isnull(sum(Round(PricePAllFix*Quantity,2)),0) from CashVoucherContents where CashVoucherID=@CashVoucherID 
   select @PosNumber=1
  end 
 
  
 --insert into test values(@Percent,@KindDiscont,getdate())

 declare gt cursor  for
 select ID, PriceN, PriceP, PricePAll, VAT, TFS, WareCost, WareVAT, Quantity, CostN, KindRound, DiscountSum
 from #t
 order by PricePAll Desc       
 --order by ID
        
 select @DiscountSum=0 --, @CurDate=getdate()

 begin transaction

 if exists(select 1 from CashVoucher where IDD=@CashVoucherID and Status!=0) 
  begin
   rollback transaction raiserror 20000 'Чек нельзя изменять!'
   return 1
  end

 open gt                                                     //пока не используем в @gtTFS будет группа товара 
 fetch gt into @gtID,@gtPriceN,@gtPriceP,@gtPricePAll,@gtVAT,@gtTFS,@gtWareCost,@gtWareVAT,@gtQuantity,@gtCostN,@gtKindRound,@gtDiscountSum  
 while @@sqlstatus=0
  begin
   
    select @TMPCOST=@gtCostN+@gtDiscountSum, @gtPriceN=@gtPricePAll, @Percent=@CardPercent
   
    if @KindDiscont=6
     begin
      --if @PosNumber=1 
      -- select @Percent=0
      -- else   
         --select @Percent=DCGetDiscountAp_f(P.PriceF,C.PriceP-C.WareCost,C.PriceP,C.PricePAll,C.Quantity, @PosNumber, @CheckSum)
         select @Percent=DCGetDiscountAp_f(P.PriceF,C.PriceP-C.WareCost,C.PriceP,C.PricePAllFix,C.Quantity, @PosNumber, @CheckSum, C.VAT, C.GroupID, C.WareVAT)
         from CashVoucherContents C, CashVoucher CV, PriceList P 
         where C.CashVoucherID=@CashVoucherID and
               C.ID=@gtID and
               CV.IDD=C.CashVoucherID and
               P.LocWareHouseID=CV.LocWareHouseID and 
               P.TMCID=C.TMCID and  
               P.BarCode=C.BarCode and
               P.PricePAll=C.PricePAllFix and
               P.MeasureName=C.MeasureName and
               P.WareCost=C.WareCost
            
      select @PosNumber=@PosNumber+1  
     end
    
    //для ижици это закоментить!!!
    if @gtTFS in (1,5,6) and @KindDiscont=7 
      select @Percent=1
     
    if @KindDiscont=1 or @KindDiscont=3 or @KindDiscont=4 or @KindDiscont=5 or @KindDiscont=6 or @KindDiscont=7 or @KindDiscont=8
      select @gtPricePAll=round((@gtPricePAll*(1-@Percent*0.01)),2)
        
    if @KindDiscont=2 
      begin
       select @gtPricePAll=round( (@gtPriceP-(@gtWareCost*(@Percent*0.01)))*(1+@gtVAT*0.01) ,2)  
       if @gtPricePAll>@gtPriceN
         select @Percent=0, @gtPricePAll=@gtPriceN --тут розница до скидки
      end 

    if @KindDiscont!=3 and @KindDiscont!=4 and @KindDiscont!=6 and @KindDiscont!=8 and @gtWareCost<@gtPriceP-round(@gtPricePAll/(1+@gtVAT*0.01),2) 
         --and (@CurDate<convert(datetime,'2018.01.01') or @CurDate>=convert(datetime,'2018.01.01') and @KindDiscont!=4)
      begin
        select @gtPricePAll=(@gtPriceP-@gtWareCost)*(1+@gtVAT*0.01)
        if @gtWareCost=0
          select @Percent=0, @gtPricePAll=@gtPriceN --тут розница до скидки
         else 
          select @Percent=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
      end
       else -- новое для типа 4 70 проц. от цены
        if @KindDiscont=4 and @gtPricePAll<round(@gtPriceN*0.30,2) --and @CurDate>=convert(datetime,'2018.01.01')
         begin
          select @gtPricePAll=round(@gtPriceN*0.30,2)
          select @Percent=round(100-(@gtPricePAll/(@TMPCOST/@gtQuantity))*100,2)
         end
       else -- для типа 8  цена товаров мин. 1 копейка
        if @KindDiscont=8 and @gtPricePAll<0.01
         begin
          select @gtPricePAll=0.01
          select @Percent=99.99
         end         
         
     --большого смысла нет так как вверху цена округлилась по математике если только переменные перевести на тип деньги   
     exec RulesOfRoundOff @gtKindRound,@gtPricePAll,@gtPricePAll out,@RoundOff out,@Result out 
      
     exec RulesOfRoundOff @gtKindRound,Round(@gtPricePAll*@gtQuantity,4),@gtCostN out,@RoundOff out,@Result out
    
     --общее для всех определяем цену без НДС новую
    select @gtPriceN=round(@gtPricePAll/(1+@gtVAT*0.01),2)
    select @gtDiscountSum=@TMPCOST-@gtCostN
    select @DiscountSum=@DiscountSum+@gtDiscountSum

    update CashVoucherContents
    set PriceN=@gtPriceN,
        PricePAll=@gtPricePAll,
        CostN=@gtCostN,
        RestOfRound=@RoundOff,
        DiscountCardID=@DiscountCardID,
        Discount=@Percent,
        DiscountSum=@gtDiscountSum 
    from CashVoucherContents 
    where CashVoucherID=@CashVoucherID and ID=@gtID
 
  
    fetch gt into @gtID,@gtPriceN,@gtPriceP,@gtPricePAll,@gtVAT,@gtTFS,@gtWareCost,@gtWareVAT,@gtQuantity,@gtCostN,@gtKindRound,@gtDiscountSum  

  end 
 close gt 

/*  не проставляем пока нет другой накопительной системы кроме бальной так как в ней не должны учавствовать позиции на которые есть скидки
 if @DiscountCardID!=0
  update CashVoucherContents
   set DiscountCardID=@DiscountCardID
  from CashVoucherContents (index Voucher_idx)
  where CashVoucherID=@CashVoucherID and
        DiscountCardID=0 and
        --TypeTMC!=3 and товары по фикс ценам тоже идут в накопления 2016 02
        TypeTMC!=-1
 */

 commit transaction 

 return 1 
end
/
grant execute on AptekaSetDiscountCard to PUBLIC
/
