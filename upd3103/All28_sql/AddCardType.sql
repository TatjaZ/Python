if not exists(select 1 from DiscountTypes where ID=8) then
  insert into DiscountTypes (ID,Comments,OnOff,IsDiscount,ChSum)
  values (8,'������ ���������� ������ 10 ������ ��� ���������',1,1,0)
end if
/