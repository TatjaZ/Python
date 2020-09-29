# # Пример который показывает, что функция, это класс
# def hello_world():
#     print('Hello world1!')
# print (type(hello_world))
#
# #Мы можем хранить функции в переменных:
# hello = hello_world
# hello()
#
# #Определять функции внутри других функций:
# def wrapper_function():
#     def hello_world1():
#         print('Hello world2!')
#     return hello_world1()
# wrapper_function()
#
# #Передавать функции в качестве аргументов и возвращать их из других функций:
# def higher_order(func):
#     print('Получена функция {} в качестве аргумента'.format(func))
#     func()
#     return func
# higher_order(hello_world)

#Декораторы
def decorator_function(func):
    def wrapper():
        print('Функция-обёртка!')
        print('Оборачиваемая функция: {}'.format(func))
        print('Выполняем обёрнутую функцию...')
        func()
        print('Выходим из обёртки')
    return wrapper

@decorator_function
def hello_world():
    print('Hello world!')
hello_world()
