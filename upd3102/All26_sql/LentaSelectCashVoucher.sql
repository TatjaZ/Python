if exists(select 1 from sys.sysprocedure where proc_name = 'LentaSelectCashVoucher') then
   drop procedure LentaSelectCashVoucher
end if
/


create procedure LentaSelectCashVoucher 
(
 @LentaID numeric(10),
 @CashNumber varchar(15)
)
as
begin
 declare @Isclose smallint,@RestIn numeric(18,2),@RestOut numeric(18,2),
         @CashSum numeric(18,2),@CardSum numeric(18,2),@NoCashSum numeric(18,2),
         @CashStornoSum numeric(18,2),@CardStornoSum numeric(18,2),@NoCashStornoSum numeric(18,2),
         @StornoCount integer,@ReturnCount integer,@CashSumR numeric(18,2),@CashStornoSumR numeric(18,2),
         @IsShowTovar smallint

 select @IsShowTovar=0

 if @LentaID<0
  select @LentaID=abs(@LentaID), @IsShowTovar=1

 select @Isclose=IsClose,@RestIn=RestIn,@RestOut=RestOut
 from Lenta
 where ID=@LentaID and
       CashNumber=@CashNumber

 select @CashSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=1 and
       P.CashVoucherID=CV.IDD and
       P.Kind=0

 select @CardSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=1 and
       P.CashVoucherID=CV.IDD and
       P.Kind=1

 select @NoCashSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=1 and
       P.CashVoucherID=CV.IDD and
       P.Kind>1 

 select @CashStornoSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=2 and
       P.CashVoucherID=CV.IDD and
       P.Kind=0 

 select @CardStornoSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=2 and
       P.CashVoucherID=CV.IDD and
       P.Kind=1 

 select @NoCashStornoSum=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=0 and  
       CV.Status=2 and
       P.CashVoucherID=CV.IDD and
       P.Kind>1 
--
 select @CashSumR=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=1 and  
       CV.Status=1 and
       P.CashVoucherID=CV.IDD

 select @CashStornoSumR=isnull(sum(P.SumPay),0) 
 from CashVoucher CV, CashVoucherPayment P 
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=1 and  
       CV.Status=2 and
       P.CashVoucherID=CV.IDD

 select @StornoCount=isnull(count(*),0)
 from CashVoucher CV
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Status=2

 select @ReturnCount=isnull(count(*),0)
 from CashVoucher CV
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       CV.Kind=1


 select CV.LentaID,CV.CashNumber,CV.IDD,CV.IsLoad,CV.Kind,CV.Number,CV.Status,CV.VoucherDate,CV.VoucherTime,
        WHMRP.Name CasherName,WareHouse.Name WHName,
        C.Name,C.MeasureName,C.BarCode,C.CostN,C.Quantity,C.PricePAll,C.ID,C.RestOfRound, C.VAT,
        Round(C.CostN-C.CostN/(1+C.VAT*0.01), 2) VatSum, C.DiscountSum,
       
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=0) V_Cash, 
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=1) V_Card,
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind>1) V_Other,
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=2) V_ChekAndHalva,--  Чеки и Халва
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=3) V_OtherPay,  --любые прочие виды 
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=4) V_Credit,  -- Кредит
        (select isnull(sum(P.SumPay),0) from CashVoucherPayment P where P.CashVoucherID=CV.IDD and P.Kind=5) V_Sertif,  -- Подарочный сертификат
        

        (select SK.ID  from SKKODocument SK where SK.Kind=case when CV.Kind=0 then 1 else 4 end and SK.SourceID=CV.IDD and SK.CashNumber=CV.CashNumber) SKNO_ID,
        (select SK.UIDStr from SKKODocument SK where SK.Kind=case when CV.Kind=0 then 1 else 4 end and SK.SourceID=CV.IDD and SK.CashNumber=CV.CashNumber) SKNO_UIDStr,

        @Isclose IsClose,@RestIn RestIn,@RestOut RestOut,
        @CashSum CashSum,@CardSum CardSum,@NoCashSum NoCashSum,
        @CashStornoSum CashStornoSum,@CardStornoSum CardStornoSum,@NoCashStornoSum NoCashStornoSum,
        @StornoCount StornoCount,@ReturnCount ReturnCount,@CashSumR CashSumR,@CashStornoSumR CashStornoSumR
 from CashVoucher CV, WHMRP, WareHouse, CashVoucherContents C
 where CV.LentaID=@LentaID and
       CV.CashNumber=@CashNumber and
       (@IsShowTovar=1 or CV.Number>0) and 
       WHMRP.ID=CV.WHMRPID and
       WareHouse.ID=CV.LocWareHouseID and
       C.CashVoucherID=CV.IDD
 return 1
 
/*
1 - чек продажи  (платежный документ) SourceID= CashVoucher.IDD 
2 - внесение наличных денежныхсредств SourceID= LentaTurn.ID 
3 - выдача наличных денежных средств SourceID= LentaTurn.ID
4 - чек возврата (возврат денежных средств) SourceID= CashVoucher.IDD 
5 - аннулирование SourceID= CashVoucher.IDD аннулируемого чека
*/ 
end
/
grant execute on LentaSelectCashVoucher to PUBLIC
/
