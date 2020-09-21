#! /bin/bash
# Закрываем кассовую программу и убиваем sybase
killall OrdersClient.exe
killall CashTerminal.exe
sudo killall dbsrv50.exe
sudo killall dbeng50.exe
sudo killall dbclient.exe

sleep 2

# Делаем копию базы
cp /home/cashier/.wine/drive_c/PSTrade/DB/TRADELOCAL.DB /home/cashier/.wine/drive_c/PSTrade/DB/TRADELOCAL_210920.DB 

# All27 для 2.0
cd All27_sql/
DISLPAY=:0 wine ConsoleUpdater2.exe AptekaSetDiscountcard_All27.sql
DISLPAY=:0 wine ConsoleUpdater2.exe CashVoucherSelectOpen_for_2_0.sql
sleep 2
cd ..

# All28 для 2.0
# Сохраняем старую версию файлов
mv /home/cashier/.wine/drive_c/windows/system32/Discount.dll /home/cashier/.wine/drive_c/windows/system32/Discount_210920.dll
# Копируем новую версию
cp Discount.dll /home/cashier/.wine/drive_c/windows/system32/

cd All28_sql/
DISLPAY=:0 wine ConsoleUpdater2.exe AddCardType.sql
DISLPAY=:0 wine ConsoleUpdater2.exe AptekaSetDiscountCard.sql
DISLPAY=:0 wine ConsoleUpdater2.exe SelectDop.sql
sleep 2
cd ..

# Перезагрузка
bash /home/cashier/scripts/reboot.all
