import os

if __name__ == '__main__':
    required_env_vars = [
        'LOG_BASE_DIR',
        'CONFIG_PATH',
    ]

    error = False

    for required_env_var in required_env_vars:
        if required_env_var not in os.environ:
            print('Required environment variable {} not found'.format(required_env_var))
            error = True

    if error:
        print('Requirements check failed, exiting')
        exit(1)

    if not os.path.isdir(os.environ['LOG_BASE_DIR']):
        print('LOG_BASE_DIR {} does not exist or is not a directory'.format(os.environ['LOG_BASE_DIR']))
        error = True

    if not os.path.isfile(os.environ['CONFIG_PATH']):
        print('CONFIG_PATH {} does not exist or is not a file'.format(os.environ['CONFIG_PATH']))
        error = True

    if not os.environ['CONFIG_PATH'].endswith('.csv'):
        print('CONFIG_PATH must be a .csv file'.format(os.environ['CONFIG_PATH']))
        error = True

    if error:
        print('Requirements check failed, stopping container')
        exit(1)
