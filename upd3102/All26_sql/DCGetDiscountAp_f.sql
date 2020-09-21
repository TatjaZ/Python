if exists(select 1 from sys.sysprocedure where proc_name = 'DCGetDiscountAp_f') then
   drop procedure DCGetDiscountAp_f
end if
/


create function DCGetDiscountAp_f
(
 @PriceF money,
 @PriceN money,
 @PriceP money,
 @PricePAll money, 
 @Quantity  numeric(19,4),
 @Pos int,
 @CheckSum money,
 @VAT numeric(6,2),
 @GroupID smallint,
 @IsImport smallint
)
RETURNS smallmoney
on exception resume
begin
 
   declare @Discount smallmoney;
   declare @BazStavka money; --базовая ставка
   declare @Porog money; --пороговое значение
--   declare @TradeRaise smallmoney; --старая торговая надбавка
--   declare @TradeROC smallmoney; --торговая надбавка от РОЦ (PriceF)
   declare @NewTradeRaise smallmoney; --новая торговая надбавка
   declare @MinusDiscount smallmoney; --скидка 1
   declare @PosDiscount smallmoney; --скидка по позиции в чеке
   declare @NewPricePAll money;
   declare @SumPorog1 money;
   declare @SumPorog2 money;
   declare @SumPorog3 money;
   
  select @BazStavka=25.5,
         @SumPorog1=30, @SumPorog2=50, @SumPorog3=100,
         @MinusDiscount=0, @PosDiscount=0, @Discount=0; 
         
  -- 2020 04  всегда ноль этот тип скидки не работает поля PriceF прайса забрано под фикс. цену.     
  return (@Discount);
  
  select @Porog=round(@PriceF/@BazStavka,2); --,
        -- @TradeRaise=round((@PriceP/(@PriceN))*100 -100,2),
        -- @TradeROC=round((@PriceP-@PriceN)/(@PriceF)*100,2);
 /* if @TradeRaise<=0 then
   begin
    --select @Discount, @Porog, @PosDiscount,@MinusDiscount,@TradeRaise,@TradeRaise 
    return (@Discount);
   end
   end if;  
  */
  if @CheckSum<@SumPorog1 then
   begin
    return (@Discount);
   end
   end if;  
         
  
  if @GroupID!=1 and @GroupID!=5 then -- не медикамент и не изделия мед.назначения in (2,3,4,6,7) then
  begin
    if @CheckSum>=@SumPorog1 and @CheckSum<@SumPorog2 then
    begin
      if @GroupID=6 then select @Discount=1.74  --МЕДТЕХНИКА
      /*elseif @GroupID=2 then select @Discount=3 --БАД
      elseif @GroupID=3 then select @Discount=3 --КОСМЕТИКА
      elseif @GroupID=4 then select @Discount=3 --пищпродукт
      elseif @GroupID=7 then select @Discount=3 --ТНП - нет такой группы в бэке*/
      else select @Discount=3
      end if;
    end
    elseif @CheckSum>=@SumPorog2 and @CheckSum<@SumPorog3 then
    begin
      if @GroupID=6 then select @Discount=1.74  --МЕДТЕХНИКА
      /*elseif @GroupID=2 then select @Discount=5 --БАД
      elseif @GroupID=3 then select @Discount=5 --КОСМЕТИКА
      elseif @GroupID=4 then select @Discount=5 --ПРОЧЕЕ
      elseif @GroupID=7 then select @Discount=5 --ТНП*/
      else select @Discount=5
      end if;
   
    end
    elseif @CheckSum>=@SumPorog3 then
    begin
      if @GroupID=6 then select @Discount=2.33  --МЕДТЕХНИКА
      /*elseif @GroupID=2 then select @Discount=7 --БАД
      elseif @GroupID=3 then select @Discount=7 --КОСМЕТИКА
      elseif @GroupID=4 then select @Discount=7 --ПРОЧЕЕ
      elseif @GroupID=7 then select @Discount=7 --ТНП*/
      else select @Discount=7
      end if;
    
    end;
    end if;

    --скидка на позицию не применяется

    return(@Discount);
  end;
  end if;

 --определяем скидку доп. за позицию
 if @Pos>1 then
  begin
    --select @PosDiscount= round( 0.3 + 0.1*@Pos, 2);
    select @PosDiscount= round( 0.5 + 0.3*(@Pos-2), 2);
    select @PosDiscount=round( @PosDiscount + 0.3*(Round(@Quantity,0)-1), 2);
    --if (@PricePAll > 5) and (@Quantity>=1.5) then
    --select @PosDiscount=round( @PosDiscount + 0.1*(Round(@Quantity,0) - 1),2 )
    --end if;  
  end;        
  end if;

  --ЛС Импорт
  if @GroupID=1 and @IsImport>=0 then
   if @CheckSum>=@SumPorog1 and @CheckSum<@SumPorog2 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=39 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=26
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=24
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=21
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=14
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=12
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=10
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=5
    elseif @Porog>10 then select @MinusDiscount=1
    end if;    
   end 
   elseif @CheckSum>=@SumPorog2 and @CheckSum<@SumPorog3 then
   begin
    if  @Porog<=0.1 then select @MinusDiscount=39
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=24
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=22
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=19
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=13
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=8
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=9
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=2.5
    elseif @Porog>10 then select @MinusDiscount=1
    end if;     
   end 
   elseif @CheckSum>=@SumPorog3 then
   begin
    if  @Porog<=0.1 then select @MinusDiscount=39
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=20
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=14
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=13
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=11
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=6
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=8
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=2.5
    elseif @Porog>10 then select @MinusDiscount=1
    end if;      
   end;
   end if;
  end if; 
  
  --ЛС Беларусь
  if @GroupID=1 and @IsImport<0 then
   if @CheckSum>=@SumPorog1 and @CheckSum<@SumPorog2 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=39 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=36
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=34
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=30
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=19
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=17
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=14
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=7
    elseif @Porog>10 then select @MinusDiscount=2.8
    end if;    
   end 
   elseif @CheckSum>=@SumPorog2 and @CheckSum<@SumPorog3 then
   begin
    if  @Porog<=0.1 then select @MinusDiscount=39
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=34
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=32
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=28
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=17
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=15
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=12
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=6
    elseif @Porog>10 then select @MinusDiscount=2.5
    end if;     
   end 
   elseif @CheckSum>=@SumPorog3 then
   begin
    if  @Porog<=0.1 then select @MinusDiscount=39
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=32
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=30
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=26
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=15
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=13
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=10
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=5
    elseif @Porog>10 then select @MinusDiscount=2.5
    end if;      
   end;
   end if;
  end if;
  
    --ИМН Импорт
  if @GroupID=5 and @IsImport>=0 then
   if @CheckSum>=@SumPorog1 and @CheckSum<@SumPorog2 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=31
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=26
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=25
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=23
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=23
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=9
    elseif @Porog>10 then select @MinusDiscount=9
    end if;    
   end 
   elseif @CheckSum>=@SumPorog2 and @CheckSum<@SumPorog3 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=26
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=23
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=23
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=20
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=20
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=8
    elseif @Porog>10 then select @MinusDiscount=8
    end if;     
   end 
   elseif @CheckSum>=@SumPorog3 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=26
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=23
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=23
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=20
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=20
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=8
    elseif @Porog>10 then select @MinusDiscount=8
    end if;      
   end;
   end if;
  end if; 

    --ИМН Беларусь
  if @GroupID=5 and @IsImport<0 then
   if @CheckSum>=@SumPorog1 and @CheckSum<@SumPorog2 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=36
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=30
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=27
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=23
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=23
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=9
    elseif @Porog>10 then select @MinusDiscount=9
    end if;    
   end 
   elseif @CheckSum>=@SumPorog2 and @CheckSum<@SumPorog3 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=34
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=28
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=25
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=21
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=21
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=8
    elseif @Porog>10 then select @MinusDiscount=8
    end if;     
   end 
   elseif @CheckSum>=@SumPorog3 then
   begin
    if @Porog<=0.1 then select @MinusDiscount=41 
    elseif @Porog>0.1 and @Porog<=0.25 then select @MinusDiscount=41
    elseif @Porog>0.25 and @Porog<=0.5 then select @MinusDiscount=31
    elseif @Porog>0.5 and @Porog<=1 then select @MinusDiscount=26
    elseif @Porog>1 and @Porog<=1.5 then select @MinusDiscount=23
    elseif @Porog>1.5 and @Porog<=3 then select @MinusDiscount=20
    elseif @Porog>3 and @Porog<=5 then select @MinusDiscount=20
    elseif @Porog>5 and @Porog<=10 then select @MinusDiscount=8
    elseif @Porog>10 then select @MinusDiscount=8
    end if;      
   end;
   end if;
  end if;   
  
  --select @NewTradeRaise=@TradeRaise-@MinusDiscount-@PosDiscount ;
 -- select @NewTradeRaise=@TradeRaise-(@TradeRaise*(@MinusDiscount+(@PosDiscount/@TradeROC*100))*0.01);
  select @NewTradeRaise = @MinusDiscount-@PosDiscount;
  if @NewTradeRaise<0 then
    select @NewTradeRaise=0;
  end if;  
  select @NewPricePAll = round(@PriceF*(1 + @NewTradeRaise/100)*(1 + @VAT/100),2);
  
  --select @Discount= round(100 - @PriceN*(1+@NewTradeRaise/100)/@PriceP*100,2);
  select @Discount= round(100 - @NewPricePAll/@PricePAll*100,2);
  if @Discount<0 then
   select @Discount=0;
  end if;
  
  --select @Discount, @Porog, @PosDiscount,@MinusDiscount,@NewPricePAll,@NewTradeRaise; 
  
  return (@Discount);

end
/
grant execute on DCGetDiscountAp_f to PUBLIC
/
