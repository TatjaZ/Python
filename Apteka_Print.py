import os
import shutil

cash_main = '/home/cashier/.wine/drive_c/windows/CashMain.ini'
dest_dir = '/home/cashier/.wine/drive_c/windows'
current_dir = os.getcwd()



def printApt(file, coding):
    try:
        doc = open(file, encoding=coding)
        data = doc.readlines()
        doc.close()
        s1 = 0
        s2 = 0
        i = 0
        line_found = 0
        aptekaRequest1 = '#          ДОСТАВКА ИЗ АПТЕКИ НА ДОМ           #\n'
        aptekaRequest2 = '#           +375(29/33/25) 683-87-87           #\n'
        aptekaRequest3 = '#                apteka-adel.by                #\n'
        string = ';количество строк для прогона после печати умалч.=6 \n\
PrinterFeedCount=6 \n\
;Печатать вид чека 0 - Стандартный, 1 - С заголовком предыдущего, 2 - Окончание текущего\n\
PrinteredFeedText=2\n\
;Строки которые печатаются с первой по шестую. Если 0 то не печатать\n\
PrinterFeedText1=          ДОСТАВКА ИЗ АПТЕКИ НА ДОМ           \n\
PrinterFeedText2=0\n\
PrinterFeedText3=0\n\
PrinterFeedText4=0\n\
PrinterFeedText5=0\n\
PrinterFeedText6=0\n'
        for line in data:
            # if line.startswith('PrinterFeedText'):
            #     line_found += 1
            #     if not s1 == 0:
            #         s2 = line.split('=')[1]
            #         line = line.split('=')[0]+'='+s1
            #     s1 =line.split('=')[1]
            #     if not s2 == 0:
            #         s1 = s2
            # if line.startswith('PrinteredFeedText'):
            #     line_found += 1
            #     line = line.split('=')[0] +'='+'2\n'
            # if line_found == 0:
            #     if line.startswith('PassDel'):
            #         line = string + line
            # data[i] = line
            # if line.startswith('PrinterFeedText1'):
            #     data[i] = line.split('=')[0]+'='+ aptekaRequest1
            if line.endswith(aptekaRequest1) or line.endswith('ДОСТАВКА ИЗ АПТЕКИ НА ДОМ\n'):
                data[i] = line.split('=')[0] + '=' + '\n'
            # if line.startswith('PrinterFeedText2'):
            #     data[i] = line.split('=')[0]+'='+ aptekaRequest2
            # if line.startswith('PrinterFeedText3'):
            #     data[i] = line.split('=')[0]+'='+ aptekaRequest3
            # if line.startswith('PrinterFeedText4'):
            #     data[i] = line.split('=')[0]+'='+ ''
            # if line.startswith('PrinterFeedText5'):
            #     data[i] = line.split('=')[0]+'='+ ''
            i+=1
        with open(file, 'w') as print_apt:
            print_apt.writelines(data)
            print_apt.close()

    except (SystemError):
        print("Ошибка при изменении ини файла")

def checkKSAtype():
    result = subprocess.check_output(['cut', '-d:', '-f1', '/etc/passwd']).decode('utf-8')
    users = []
    for line in result.splitlines():
        name = line.split()[0]
        if name not in users:
            users.append(name)
    if 'cblock' in users:
        ksaType = 1
    else:
         ksaType = 0
    return ksaType

def copy_ini(path, dest):
    try:
        shutil.copy(path, dest)
    except (OSError, IOError):
        print("Ошиюка при копировании файла")


def move_ini(file, dest):
    try:
        if 'CashMain.ini' in os.listdir(dest):
            os.chdir(dest)
            os.remove(dest + '/CashMain.ini')
            os.chdir(current_dir)
        shutil.move(file, dest)
    except (OSError, IOError):
        print("Ошиюка при копировании файла")




copy_ini(cash_main, current_dir)
os.system('dos2unix CashMain.ini')
os.system('iconv -f WINDOWS-1251 -t UTF-8 -o CashMain.ini CashMain.ini')
printApt('CashMain.ini', None)
os.system('iconv -f UTF-8 -t WINDOWS-1251 -o CashMain.ini CashMain.ini')
os.system('unix2dos CashMain.ini')
move_ini('CashMain.ini', dest_dir)

