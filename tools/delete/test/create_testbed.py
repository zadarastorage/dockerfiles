import os
import time

root_dirs = [
    '/export/delete/1',
    '/export/delete/1/2',
    '/export/delete/1/2/3',
    '/export/delete/2',
    '/export/delete/3',
    '/export/delete/4',
    '/export/delete/5'
]

for directory in root_dirs:
    if not os.path.isdir(directory):
        os.makedirs(directory)

    for i in range(5):
        path = os.path.join(directory, str(i) + '.log')
        open(path, 'a').close()
        if i > 3:
            old = time.time() - 60 * 60 * 24 * 45
            os.utime(path, (old, old))

    for i in range(6, 11):
        path = os.path.join(directory, str(i) + '.txt')
        open(path, 'a').close()
        if i > 8:
            old = time.time() - 60 * 60 * 24 * 45
            os.utime(path, (old, old))
