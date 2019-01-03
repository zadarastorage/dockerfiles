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

files = [
    {
        'path': '1/TestCase_29days.log',
        'age': 29
    },
    {
        'path': '1/TestCase_31days.log',
        'age': 31
    },
    {
        'path': '1/TestCase2_44days.log',
        'age': 44
    },
    {
        'path': '1/TestCase2_46days.log',
        'age': 46
    },
    {
        'path': '1/TestCase3_59days.log',
        'age': 59
    },
    {
        'path': '1/TestCase3_61days.log',
        'age': 61
    }
]


def create_file_set_age(path, age_days):
    full_path = os.path.join(root, path)
    open(full_path, 'a').close()
    age = time.time() - 60 * 60 * 24 * age_days
    os.utime(full_path, (age, age))


root = '/mnt/delete'
for file in files:
    create_file_set_age(file['path'], file['age'])

# for directory in root_dirs:
#     if not os.path.isdir(directory):
#         os.makedirs(directory)
#
#     for i in range(5):
#         path = os.path.join(directory, str(i) + '.log')
#         open(path, 'a').close()
#         if i > 3:
#             old = time.time() - 60 * 60 * 24 * 45
#             os.utime(path, (old, old))
#
#     for i in range(6, 11):
#         path = os.path.join(directory, str(i) + '.txt')
#         open(path, 'a').close()
#         if i > 8:
#             old = time.time() - 60 * 60 * 24 * 45
#             os.utime(path, (old, old))
