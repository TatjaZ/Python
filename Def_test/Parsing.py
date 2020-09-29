from typing import List, Any

fp = open('access.log', 'r')
lines = fp.readlines()
fp.close()
print('Количество запросов: ' + str(len(lines)))
def parse_line(line):
    ip, rest = line.split(" ", maxsplit=1)
    rest, user_agent =  line[:-6].rsplit(maxsplit=1)
    return {'ip': ip, 'user_agent': user_agent}
parse_line(lines[0])
# Requests = [ ]
# for line in lines:
#     r = parse_line(line)
#     requests.append(r)
# ips = [request['ip'] for request in requests]
# print('Количество уникальных ip: ' + str(len(set(ips))))
# user_agents = [request['user_agent'] for request in requests]
# print('Количество браузеров: ' + str(len(set(user_agents))))
# print('Список браузеров: ' + '\n'.join(set(user_agents)))
# ua_count = {user_agent: 0 for user_agent in user_agents}
# for request in requests:
#     r_user_agent = request["user_agent"]
#     ua_count[r_user_agent] += 1
# ua_count