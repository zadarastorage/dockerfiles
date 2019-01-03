import csv
import datetime
import fnmatch
import os
import shutil
import time
import traceback

config_file = os.environ['CONFIG_PATH']

log_base_dir = os.environ['LOG_BASE_DIR']
log_timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%d_%H-%M-%S")
log_dir = os.path.join(log_base_dir, log_timestamp)
run_log_path = os.path.join(log_dir, 'run.log')
delete_log_path = os.path.join(log_dir, 'delete.log')
config_backup_path = os.path.join(log_dir, 'config.csv')

if os.environ['DRY_RUN'].lower() == 'false' or os.environ['DRY_RUN'].lower() == 'disabled':
    dry_run = False
else:
    dry_run = True

if os.environ['CASE_SENSITIVE_PATTERNS'] == 'false' or os.environ['CASE_SENSITIVE_PATTERNS'] == 'disabled':
    case_sensitive_patterns = False
else:
    case_sensitive_patterns = True


# get timestamp for logs
def get_timestamp():
    return datetime.datetime.utcnow().strftime("%Y-%m-%d_%H:%M:%S")


# create directory if does not exist
def create_directory(path):
    if not os.path.isdir(path):
        os.makedirs(path)


# check if pid is running
def check_pid(pid):
    """ Check For the existence of a unix pid. """
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True


# check is previous run is still in progress, if so exit
def check_create_pid_file(pid_file_path):
    pid = str(os.getpid())
    if os.path.isfile(pid_file_path):
        with open(pid_file_path, 'r') as file_pid:
            running_pid = file_pid.read()
        if check_pid(int(running_pid)):
            print_and_log("Previous run in progress, exiting")
            exit(1)
    open(pid_file, 'w').write(pid)


# helper function to print and log a message
def print_and_log(message, log_path=run_log_path, include_timestamp=True, print_message=False):
    if print_message:
        if include_timestamp:
            print(get_timestamp() + '\t' + message)
        else:
            print(message)

    with open(log_path, 'a+') as log:
        if include_timestamp:
            message = get_timestamp() + '\t' + message
        log.write(message + '\n')


def print_and_log_error(exception):
    log_entry = str(exception) + '\n' + "Exception in user code:\n" \
                + '-' * 60 + '\n' + traceback.format_exc() + '\n' + '-' * 60
    print_and_log(log_entry)


def backup_config_file():
    if os.path.isfile(config_file):
        shutil.copy2(config_file, config_backup_path)
    else:
        print_and_log('Config file not found, exiting')
        exit(1)


def get_config():
    try:
        config_object = {}
        with open(config_file) as csv_file:
            reader = csv.DictReader(csv_file)
            for row in reader:
                if row['root'] not in config_object:
                    config_object[row['root']] = []
                config_object[row['root']].append({
                    'pattern': row['pattern'],
                    'retention_days': row['retention_days']
                })
        return config_object
    except Exception as error:
        print_and_log("Error parsing configuration file")
        print_and_log_error(error)
        exit(1)


def log_and_delete(path, mtime):
    try:
        log_entry = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d_%H:%M:%S") + '\t' + path
        print_and_log(log_entry, log_path=delete_log_path, print_message=False)
        if not dry_run:
            os.unlink(path)
    except Exception as error:
        print_and_log("Error logging and deleting file {}".format(path))
        print_and_log_error(error)


def loop_directories(config):
    print_and_log('{} root directories to scan'.format(len(config)))
    for directory in config:
        if not os.path.isdir(directory):
            print_and_log('Root directory {} not found! skipping'.format(directory))
            continue
        print_and_log('Walking {}'.format(directory))
        print_and_log('Patterns: {}'.format(config[directory]))
        found_files = 0
        for root, dirs, files in os.walk(directory):
            for name in files:
                file_path = os.path.join(root, name)
                file_mtime = os.stat(file_path).st_mtime
                pattern_matches = 0
                retention_matches = 0
                for pattern in config[directory]:
                    expiration = time.time() - 60 * 60 * 24 * int(pattern['retention_days'])
                    if case_sensitive_patterns:
                        pattern_match = fnmatch.fnmatch(name, pattern['pattern'])
                    else:
                        pattern_match = fnmatch.fnmatch(name.lower(), pattern['pattern'].lower())
                    if pattern_match:
                        pattern_matches += 1
                        if file_mtime < expiration:
                            retention_matches += 1
                if pattern_matches > 0 and pattern_matches == retention_matches:
                    log_and_delete(file_path, file_mtime)
                    found_files += 1
        print_and_log('{} files found and deleted'.format(found_files))


if __name__ == '__main__':

    pid_file = "/dev/shm/removal.pid"

    try:
        check_create_pid_file(pid_file)
        create_directory(log_dir)
        print_and_log('Run start')
        if dry_run:
            print_and_log('Dry run enabled, not deleting files')
        backup_config_file()
        conf = get_config()
        loop_directories(conf)
        print_and_log('Run complete')
    except Exception as outer_error:
        print_and_log_error(outer_error)
    finally:
        if os.path.exists(pid_file):
            os.unlink(pid_file)
