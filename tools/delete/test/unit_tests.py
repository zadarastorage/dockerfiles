import unittest
import sys
import os
import time

root = '/mnt/delete'

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


def create_file_set_age(root, path, age_days):
    full_path = os.path.join(root, path)
    open(full_path, 'a').close()
    age = time.time() - 60 * 60 * 24 * age_days
    os.utime(full_path, (age, age))


def create_testbed():
    for file in files:
        create_file_set_age(root, file['path'], file['age'])


class TestCase(unittest.TestCase):
    def setUp(self):
        create_testbed()
        os.environ["CONFIG_PATH"] = 'test_config.csv'
        os.environ["LOG_BASE_DIR"] = '/mnt/delete/logs'
        os.environ["DRY_RUN"] = 'False'
        os.environ["CASE_SENSITIVE_PATTERNS"] = 'False'
        sys.path.insert(0, '../')
        import delete
        delete.main()

    def test_NMinusOneFilesNotDeleted(self):
        self.assertTrue(os.path.isfile(os.path.join(root, '1/TestCase_29days.log')))
        self.assertTrue(os.path.isfile(os.path.join(root, '1/TestCase2_44days.log')))
        self.assertTrue(os.path.isfile(os.path.join(root, '1/TestCase3_59days.log')))

    def test_NPlusOneFilesDeleted(self):
        self.assertFalse(os.path.isfile(os.path.join(root, '1/TestCase_31days.log')))
        self.assertFalse(os.path.isfile(os.path.join(root, '1/TestCase2_46days.log')))
        self.assertFalse(os.path.isfile(os.path.join(root, '1/TestCase3_61days.log')))


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestCase)
    unittest.TextTestRunner(verbosity=2).run(suite)

