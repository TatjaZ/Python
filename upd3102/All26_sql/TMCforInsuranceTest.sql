if not exists(select 1 from WHNomenclatureGroup where ID=-106) then
 insert into WHNomenclatureGroup
  values (-106,0,'JTI-èíãîññòğàõ')
end if
/

if exists(select 1 from sys.sysprocedure where proc_name = 'TMCforInsuranceTest') then
   drop procedure TMCforInsuranceTest
end if
/


create procedure TMCforInsuranceTest 
(
 @CashVoucherID numeric(10),
 @CustomerID numeric(10)
)
as
begin
/*
 when @CustomerID=-102 then 0  --ÒÀÑÊ               
  when @CustomerID=-103 then 0 --ÁÅËÍÅÔÒÅÑÒĞÀÕ
  when @CustomerID=-104 then 0 --ÏĞÎÌÒĞÀÍÑÈÍÂÅÑÒ
  when @CustomerID=-105 then 16 --ÁÅËÊÎÎÏÑÒĞÀÕ
  when @CustomerID=-106 then 0  --ğåçåğâ c 2020 02 JTI-èíãîññòğàõ
  when @CustomerID=-107 then 0 --ÊÓÏÀËÀ
  when @CustomerID=-108 then 8  --ÈÍÃÎÑÑÒĞÀÕ
  when @CustomerID=-109 then 0  --ÁÅËÃÎÑÑÒĞÀÕ

*/
 /* íåò ïğîâåğêè */
 if @CustomerID!=-102 and @CustomerID!=-103 and @CustomerID!=-104 and @CustomerID!=-105 and 
    @CustomerID!=-106 and @CustomerID!=-107 and @CustomerID!=-108 and @CustomerID!=-109
 select CV.Name 
 from CashVoucher C,
      CashVoucherContents CV
 where C.IDD=@CashVoucherID*(-1)

 else
/* åñòü ïğîâåğêà */
 select CV.Name 
 from CashVoucher C,
      CashVoucherContents CV
 where C.IDD=@CashVoucherID and 
       CV.CashVoucherID=C.IDD and
       (select count(TI.TMCID) 
        from TMCforInsurance TI where TI.TMCID=CV.TMCID and 
            ( (@CustomerID=-108 and In1=1) or 
              (@CustomerID=-103 and In2=1) or
              (@CustomerID=-104 and In3=1) or
              (@CustomerID=-107 and In4=1) or
              (@CustomerID=-102 and In5=1) or
              (@CustomerID=-105 and In6=1) or
              (@CustomerID=-109 and In7=1) or
              (@CustomerID=-106 and In8=1) 
             ) 
       )=0
end
/
grant execute on TMCforInsuranceTest to PUBLIC
/
