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

# All26 для 1.5
# Сохраняем старую версию файлов
mv /home/cashier/.wine/drive_c/windows/system32/PsBackOffice.dll /home/cashier/.wine/drive_c/windows/system32/PsBackOffice_210920.dll
mv /home/cashier/.wine/drive_c/PSTrade/SKKO.dll /home/cashier/.wine/drive_c/PSTrade/SKKO_210920.dll
# Копируем новую версию
cp PsBackOffice.dll /home/cashier/.wine/drive_c/windows/system32/
cp SKKO.dll /home/cashier/.wine/drive_c/PSTrade/
# Скрипты для All26 v.1.5
cd All26_sql/
DISLPAY=:0 wine ConsoleUpdater2.exe CreateIndex_SourceID.sql
DISLPAY=:0 wine ConsoleUpdater2.exe SKNOSElect.sql
DISLPAY=:0 wine ConsoleUpdater2.exe DCGetDiscountAp_f.sql
DISLPAY=:0 wine ConsoleUpdater2.exe Dicount_proc202003_Apteka.sql
DISLPAY=:0 wine ConsoleUpdater2.exe DTSelAll.sql
DISLPAY=:0 wine ConsoleUpdater2.exe ERJournalSelectAll.sql
DISLPAY=:0 wine ConsoleUpdater2.exe LentaSelectCashVoucher.sql
DISLPAY=:0 wine ConsoleUpdater2.exe PriceListDetail.sql
DISLPAY=:0 wine ConsoleUpdater2.exe TMCforInsuranceTest.sql
sleep 2
cd ..

# All27 для 1.5
cd All27_sql/
DISLPAY=:0 wine ConsoleUpdater2.exe AptekaSetDiscountcard_All27.sql
sleep 2
cd ..

# All28 для 1.5
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
