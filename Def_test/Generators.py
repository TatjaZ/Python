def mygenerator():
    yield "Vasia"
    yield "Ivan"
    # raise StopIteration
    yield "Petr"

print(type(mygenerator()))

for i in mygenerator():
    print(i)

g=mygenerator()
# print(type(g))
print(next(g))
next(g)
print(next(g))