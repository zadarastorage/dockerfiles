#!/usr/bin/env python

import argparse
import sqlite3
import csv
import sys

# @see common/tools/zmeter.h::zmeter_device_type_t
dev_types = {'FE': 1, 'RG': 2, 'BE': 3, 'POOL': 4, 'SYSTEM': 5, 'MIRROR': 6, 'ZCACHE': 7, 'BLOCK': 10, 'NOVA': 11, 'MIGR': 13, 'OBJ': 14}
output_types = {'INFLUXDB': 1, 'ELASTICSEARCH':2, 'CSV': 3, 'JSON': 4 }
#dev_types table insert no point not having these in the DB if someone wants to use another tool also such as DB Browser

create_table = ["""CREATE TABLE 'dev_types' ( dev_type integer, 'dev_name' varchar);"""]
 
create_table.append("""INSERT INTO dev_types ('dev_type','dev_name') VALUES (1, 'FE' );""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (2, 'RG');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (3, 'BE');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (4, 'POOL');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (5, 'SYSTEM');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (6, 'MIRROR');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (7, 'ZCACHE');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (10, 'BLOCK');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (11, 'NOVA');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (13, 'MIGR');""")
create_table.append("""INSERT into dev_types ('dev_type','dev_name') values (14, 'OBJ');""")



parser = argparse.ArgumentParser(description='Convert metering database into CSV, JSON, InfluxDB Import or Elasticsearch Import,  redirect >> to file or specify --output_file')
parser.add_argument('db', help='metering DB')
parser.add_argument('-z', action='store_true', help='omit records with no I/O activity.')
parser.add_argument('-v', '--verbose', action='store_true')
parser.add_argument('-x', '--extended', action='store_true', help='output non-rw stats')
parser.add_argument('-a', '--all', action='store_true', help='output all io, zcache and system stats, not for use with csv, Influx only')
parser.add_argument('--localtime', action='store_true', help='output times in localtime (default UTC)')
parser.add_argument('--output_type', choices=output_types.keys(), help='output format for import into analysis engine')
parser.add_argument('--output_file', type=str, help='output file name')
parser.add_argument('--ro', action='store_true', help='output read io only')
parser.add_argument('--wo', action='store_true', help='output write io only')
parser.add_argument('--cloud_id', type=str, help='store the cloud_id as a parameter in the output file')
parser.add_argument('--vpsa_id', type=str, help='store the vpsa_id as a paramter in the output file if not entered vsa-xxxxxxxx id will be used')
parser.add_argument('--measurement', type=str, help='influxDB measurement category will default to "io" if not set or "system" / "zcache" if dev_type set to these or all used if -a used ')
parser.add_argument('--tsdb_id', type=str, help='influxDB target database will default to VPSA1 if no input')
parser.add_argument('--r_policy', type=str, help='influxDB retenstion policy will default to autogen if no input')
flt_group = parser.add_argument_group('Filters')
flt_group.add_argument('--dev_dbid', type=int, help='filter output by device dbid')
flt_group.add_argument('--dev_type', choices=dev_types.keys(), help='filter output by device type')
flt_group.add_argument('--dev_ext_name', help='filter output by internal device name')
flt_group.add_argument('--dev_server_name', help='filter output by internal server name, for BE devices USER/SETUP mean user/setup partitions')
flt_group.add_argument('--dev_target_name', help='filter output by target name')
flt_group.add_argument('--unixtime', type=int, help='filter output by metering time (secs from Jan 1, 1970)')


args = parser.parse_args()

if args.dev_type == 'SYSTEM':
	dev_type_str = 'system'
elif args.dev_type == 'ZCACHE':
	dev_type_str = 'zcache'
else:
	dev_type_str = 'io'

if args.measurement is None:
	measurement  = dev_type_str
if args.output_type is None:
	output_type = 0
else:
	output_type = output_types[args.output_type]

if args.tsdb_id is None:
	tsdb_id = 'VPSA1'
else:
	tsdb_id = args.tsdb_id

if args.r_policy is None:
	r_policy = 'autogen'
else:
	r_policy = args.r_policy

conn = sqlite3.connect(args.db)
cursor = conn.cursor()

#lets see if the dev_types tables exists if not lets create one

cursor.execute("""SELECT name FROM sqlite_master WHERE type='table' AND name='dev_types';""")
is_devtypes = cursor.fetchone()
if is_devtypes is None:
	for sqlins in create_table:
		if args.verbose:
			print >> sys.stderr, 'need to create dev_types on this DB'
			print >> sys.stderr, sqlins
		cursor.execute(sqlins)
		conn.commit()

else:
	cursor.execute('SELECT Count(*) FROM dev_types;')
	row_count = cursor.fetchone()
	if len(create_table)-1 != int(row_count[0]):
		if args.verbose:
			print >> sys.stderr, "need to DROP dev_types on this DB dev_types don't match"
			
		cursor.execute("""DROP TABLE 'dev_types';""")
		conn.commit()
		for sqlins in create_table:
			if args.verbose:
				print >> sys.stderr, 'need to create dev_types on this DB'
				print >> sys.stderr, sqlins
			cursor.execute(sqlins)
			conn.commit()

if args.vpsa_id is None:
	chk_dev = int(cursor.execute('SELECT COUNT(*) FROM devices WHERE dev_type=1;').fetchone()[0])
	if chk_dev > 0:
		iqn  = str(cursor.execute('SELECT devices.dev_target_name FROM devices WHERE dev_type = 1;').fetchone()[0])
		split_iqn = iqn.split(':',2)
		vpsa_id  = split_iqn[1]
else:
	vpsa_id = args.vpsa_id

if args.cloud_id is None:
		cloud_id = 'unknown_cloud'
else:
	cloud_id = args.cloud_id



common_fieldnames = ['dev_dbid', 'dev_type', 'dev_ext_name', 'dev_server_name', 'dev_target_name', 'unixtime', 'date', 'time', 'interval']
fieldnames = list(common_fieldnames)

# Prepare SELECT statements
if dev_type_str == 'io':
	if args.dev_type is None:
		query = 'SELECT dev_type, bucket, bucket_name FROM io_buckets'
	else:
		query = 'SELECT dev_type, bucket, bucket_name FROM io_buckets WHERE dev_type = {}'.format(dev_types[args.dev_type])
	if args.verbose:
		print >> sys.stderr, 'Load io buckets'
		print >> sys.stderr, query
	cursor.execute(query + ';')

	io_buckets = dict()
	bucket_names = list()
	for sql_row in cursor:
		dev_type = sql_row[0]
		bucket = sql_row[1]
		bucket_name = sql_row[2]
		if args.extended or (bucket_name.lower()=='read' or bucket_name.lower()=='write'):
			io_buckets[(dev_type, bucket)] = bucket_name
			if bucket_name not in bucket_names:
				bucket_names.append(bucket_name)

	table = 'metering_info'
	
	# >-18.07 has field total_resp_tm_us (microseconds) vs older having total_resp_tm_ms (milliseconds)
	cursor.execute("""SELECT count(*) FROM sqlite_master where name = 'metering_info' and sql like('%total_resp_tm_ms%')""")
	ms_count = int(cursor.fetchone()[0])
	if ms_count > 0:
		fields = 'bucket, '																+ \
				'ROUND( CAST(num_ios AS REAL) / interval, 3) AS iops, '					+ \
				'active_ios, io_errors, '												+ \
				'ROUND( (CAST(bytes AS REAL) / interval) / (1024*1024), 3) AS mbps, '	+ \
				'ROUND( CAST(total_resp_tm_ms AS REAL) / num_ios, 3) AS latency_ms, '	+ \
				'max_resp_tm_ms AS max_latency_ms, max_cmd '
	else:
		fields = 'bucket, '																+ \
				'ROUND( CAST(num_ios AS REAL) / interval, 3) AS iops, '					+ \
				'active_ios, io_errors, '												+ \
				'ROUND( (CAST(bytes AS REAL) / interval) / (1024*1024), 3) AS mbps, '	+ \
				'ROUND(CAST((metering_info.total_resp_tm_us / 1000) AS real) / metering_info.num_ios, 3) AS latency_ms, ' + \
				'ROUND(CAST((metering_info.max_resp_tm_us / 1000) AS real), 3) AS max_latency_ms, max_cmd '

	for bucket_name in bucket_names:
		fieldnames.append(bucket_name + '.iops')
		fieldnames.append(bucket_name + '.active_ios')
		fieldnames.append(bucket_name + '.io_errors')
		fieldnames.append(bucket_name + '.mbps')
		fieldnames.append(bucket_name + '.latency_ms')
		fieldnames.append(bucket_name + '.max_latency_ms')
		fieldnames.append(bucket_name + '.max_cmd')
elif dev_type_str == 'system':
	table = 'metering_sys_info'
	fields = 'ROUND(CAST(100.0 * cpu_user AS REAL) / (cpu_user + cpu_system + cpu_iowait + cpu_idle), 3) AS cpu_user, '		+ \
			'ROUND(CAST(100.0 * cpu_system AS REAL) / (cpu_user + cpu_system + cpu_iowait + cpu_idle), 3) AS cpu_system, '	+ \
			'ROUND(CAST(100.0 * cpu_iowait AS REAL) / (cpu_user + cpu_system + cpu_iowait + cpu_idle), 3) AS cpu_iowait, '	+ \
			'ROUND(CAST(100.0 * cpu_idle AS REAL) / (cpu_user + cpu_system + cpu_iowait + cpu_idle), 3) AS cpu_idle, '		+ \
			'memory AS mem_used, mem_alloc, mem_active '
	fieldnames.append('cpu_user')
	fieldnames.append('cpu_system')
	fieldnames.append('cpu_iowait')
	fieldnames.append('cpu_idle')
	fieldnames.append('mem_used')
	fieldnames.append('mem_alloc')
	fieldnames.append('mem_active')
#dev_type == 'zcache'
else:
	table = 'metering_zcache_info'
	fields = 'data_dirty, meta_dirty, data_clean, meta_clean, data_cb_util, meta_cb_util, ' + \
			'data_read_hit, meta_read_hit, data_write_hit, meta_write_hit '
	fieldnames.append('data_dirty')
	fieldnames.append('meta_dirty')
	fieldnames.append('data_clean')
	fieldnames.append('meta_clean')
	fieldnames.append('data_cb_util')
	fieldnames.append('meta_cb_util')
	fieldnames.append('data_read_hit')
	fieldnames.append('meta_read_hit')
	fieldnames.append('data_write_hit')
	fieldnames.append('meta_write_hit')

# Prepara WHERE statements
where = "1 "
if args.z:
	if table == 'metering_info':
		where += "AND num_ios != 0 "
	else:
		where += "AND (cpu_user != 0 or cpu_system != 0) "
if args.dev_dbid is not None:
	where += "AND {}.dev_dbid = {} ".format(table, args.dev_dbid)
if args.dev_type is not None:
	where += "AND devices.dev_type = {0} ".format(dev_types[args.dev_type])
if args.dev_ext_name is not None:
	if args.dev_ext_name != "":
		where += "AND dev_ext_name = '{0}' ".format(str(args.dev_ext_name))
	else:
		where += "AND dev_ext_name is NULL "
if args.dev_server_name is not None:
	if args.dev_server_name != "":
		where += "AND dev_server_name = '{0}' ".format(str(args.dev_server_name))
	else:
		where += "AND dev_server_name is NULL "
if args.dev_target_name is not None:
	if args.dev_target_name != "":
		where += "AND dev_target_name = '{0}' ".format(str(args.dev_target_name))
	else:
		where += "AND dev_target_name is NULL "
if args.unixtime is not None:
	where += "AND unixtime = {0} ".format(str(args.unixtime))



# http://www.sqlite.org/lang_datefunc.html
wanttime = "'unixepoch'"
if args.localtime:
	wanttime = "'unixepoch', 'localtime'"

# Build the query depending upon output type
# query output for InfluxDB, tags first then fields and finally timestamp
if output_type == 1 and dev_type_str == 'io':
	cursor.execute("""SELECT count(*) FROM sqlite_master where name = 'metering_info' and sql like('%total_resp_tm_ms%')""")
	ms_count = int(cursor.fetchone()[0])
	if ms_count > 0:
		query = 'SELECT devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name, io_buckets.bucket_name, dev_types.dev_name, ' +\
				'ROUND(CAST(metering_info.num_ios AS REAL) / interval, 3) AS iops, ROUND((CAST(metering_info.bytes AS REAL) / interval) / (1024 * 1024), 3) AS mbps, ' +\
				'ROUND(CAST(metering_info.total_resp_tm_ms AS REAL) / num_ios, 3) AS latency_ms, metering_info.active_ios, metering_info.io_errors, metering_info.max_cmd, ' +\
				'metering_info.max_resp_tm_ms AS max_latency_ms, metering_info.interval, metering_info.time AS unixtime ' +\
				'FROM  metering_info INNER JOIN devices ON (metering_info.dev_dbid = devices.dev_dbid) ' +\
				'INNER JOIN io_buckets ON (devices.dev_type = io_buckets.dev_type) AND (metering_info.bucket = io_buckets.bucket) ' +\
				'INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) AND (dev_types.dev_type = io_buckets.dev_type) ' +\
				'WHERE  '+ where + ' ' +\
				'ORDER BY metering_info.time'
	else:
		query = 'SELECT devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name, io_buckets.bucket_name, dev_types.dev_name, ' +\
				'ROUND(CAST(metering_info.num_ios AS REAL) / interval, 3) AS iops, ROUND((CAST(metering_info.bytes AS REAL) / interval) / (1024 * 1024), 3) AS mbps, ' +\
				'ROUND(CAST((metering_info.total_resp_tm_us / 1000) AS real) / metering_info.num_ios, 3) AS latency_ms, metering_info.active_ios, metering_info.io_errors, metering_info.max_cmd, ' +\
				'ROUND(CAST((metering_info.max_resp_tm_us / 1000) AS real), 3) AS max_latency_ms, metering_info.interval, metering_info.time AS unixtime ' +\
				'FROM  metering_info INNER JOIN devices ON (metering_info.dev_dbid = devices.dev_dbid) ' +\
				'INNER JOIN io_buckets ON (devices.dev_type = io_buckets.dev_type) AND (metering_info.bucket = io_buckets.bucket) ' +\
				'INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) AND (dev_types.dev_type = io_buckets.dev_type) ' +\
				'WHERE  '+ where + ' ' +\
				'ORDER BY metering_info.time'
	
	# output in InfluxDB measurement, tag, field, timestamp format as key value sets
	if args.verbose:
		print >> sys.stderr, 'Execute main query'
		print >> sys.stderr, query

	cursor.execute(query + ';')
	

	#influx list fields using list as need to preserve order at this point
	influx_fields_tags = ['dev_ext_name', 'dev_server_name', 'dev_target_name', 'bucket_name', 'dev_name']
	influx_fields_fields  = ['iops', 'mbps', 'latency_ms', 'active_ios', 'io_errors', 'max_cmd', 'max_latency_ms', 'interval']
	influx_fields = []
	for adds in influx_fields_tags:
		influx_fields.append(adds)
	for adds in influx_fields_fields:
		influx_fields.append(adds)

	influx_header = '# DML \n# CONTEXT-DATABASE: {0} \n# CONTEXT-RETENTION-POLICY: {1} \n'.format(tsdb_id, r_policy)
	influx_writer = csv.DictWriter(sys.stdout,fieldnames=influx_fields)
	sys.stdout.write(influx_header)
	
	# build line protocol sections for tags, fields and timestamp to match Influx Line Protocol https://docs.influxdata.com/influxdb/v1.1/write_protocols/line_protocol_tutorial/
	for sql_row in cursor:
		influx_row_timestamp = ""
		if len(sql_row) > 0:
			if args.verbose:
				print >> sys.stderr, str(sql_row)
			influx_row_tags = []
			influx_row_tags.append ('cloud_id=' + cloud_id)
			influx_row_tags.append('vpsa_id=' + vpsa_id)
			influx_row_fields = []
			sql_count = int(len(sql_row) -1)
					
			columns = len(influx_fields)
			#print >> sys.stderr, 'columns is ' + str(columns) + 'sql_row is ' + str(sql_count)
			if columns  == sql_count:

				columnid = 0
				
				for tkeys in influx_fields_tags:
					influx_row_tags.append(tkeys + '=' + str(sql_row[columnid]))
					if args.verbose:
						print >> sys.stderr, 'adding tag keys ' + str(tkeys) 

						print >> sys.stdout, columnid
					columnid = columnid +1
				for fkeys in influx_fields_fields:
					if (sql_row[columnid]) is None:
						influx_row_fields.append(fkeys + '=0')
					else:
						influx_row_fields.append(fkeys + '=' + str(sql_row[columnid]))
						columnid = columnid + 1
				influx_row_timestamp  = str(sql_row[sql_count])
		# elements built now write the row
				
			tags_str =  ",".join(str(bit) for bit in influx_row_tags)
			fields_str = ",".join(str(bit) for bit in influx_row_fields)

			row_str = str(str(measurement) +',' + tags_str + ' ' + fields_str +' ' + str(influx_row_timestamp) + '\n')
			if args.verbose:
				print >> sys.stderr, 'row string is ' + row_str
			sys.stdout.write(row_str)
			#influx_writer.writerow(row_str)
	if args.all: 
		#output system and zcache also
		measurement = 'system'
		query = 'SELECT dev_types.dev_name, devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name,' + \
		'ROUND(CAST(100.0 * metering_sys_info.cpu_user AS REAL) / (metering_sys_info.cpu_user + metering_sys_info.cpu_system + metering_sys_info.cpu_iowait + metering_sys_info.cpu_idle), 3) AS cpu_user,' +\
		'ROUND(CAST(100.0 * metering_sys_info.cpu_system AS REAL) / (metering_sys_info.cpu_user + metering_sys_info.cpu_system + metering_sys_info.cpu_iowait + metering_sys_info.cpu_idle), 3) AS cpu_system, ' +\
		'ROUND(CAST(100.0 * metering_sys_info.cpu_iowait AS REAL) / (metering_sys_info.cpu_user + metering_sys_info.cpu_system + metering_sys_info.cpu_iowait + metering_sys_info.cpu_idle), 3) AS cpu_iowait, ' +\
		'ROUND(CAST(100.0 * metering_sys_info.cpu_idle AS REAL) / (metering_sys_info.cpu_user + metering_sys_info.cpu_system + metering_sys_info.cpu_iowait + metering_sys_info.cpu_idle), 3) AS cpu_idle, ' +\
		'metering_sys_info.memory AS mem_used, metering_sys_info.mem_alloc, metering_sys_info.mem_active, metering_sys_info."time" FROM  metering_sys_info ' +\
		'INNER JOIN devices ON (metering_sys_info.dev_dbid = devices.dev_dbid) INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) WHERE 1 AND devices.dev_type = 5'
		if args.verbose:
			print >> sys.stderr, 'Execute system query'
			print >> sys.stderr, query

		cursor.execute(query + ';')

		influx_fields_tags = ['dev_name','dev_ext_name', 'dev_server_name', 'dev_target_name' ]
		influx_fields_fields  = ['cpu_user', 'cpu_system', 'cpu_iowait', 'cpu_idle', 'mem_used', 'mem_alloc', 'mem_active']
		influx_fields = []
		for adds in influx_fields_tags:
			influx_fields.append(adds)
		for adds in influx_fields_fields:
			influx_fields.append(adds)

		# build line protocol sections for tags, fields and timestamp to match Influx Line Protocol https://docs.influxdata.com/influxdb/v1.1/write_protocols/line_protocol_tutorial/
		for sql_row in cursor:
			influx_row_timestamp = ""
			if len(sql_row) > 0:
				if args.verbose:
					print >> sys.stderr, str(sql_row)
				influx_row_tags = []
				influx_row_tags.append ('cloud_id=' + cloud_id)
				influx_row_tags.append('vpsa_id=' + vpsa_id)
				influx_row_fields = []
				sql_count = int(len(sql_row) -1)
						
				columns = len(influx_fields)
				#print >> sys.stderr, 'columns is ' + str(columns) + 'sql_row is ' + str(sql_count)
				if columns  == sql_count:

					columnid = 0
					
					for tkeys in influx_fields_tags:
						influx_row_tags.append(tkeys + '=' + str(sql_row[columnid]))
						if args.verbose:
							print >> sys.stderr, 'adding tag keys ' + str(tkeys) 

							print >> sys.stdout, columnid
						columnid = columnid +1
					for fkeys in influx_fields_fields:
						if (sql_row[columnid]) is None:
							influx_row_fields.append(fkeys + '=0')
						else:
							influx_row_fields.append(fkeys + '=' + str(sql_row[columnid]))
							columnid = columnid + 1
					influx_row_timestamp  = str(sql_row[sql_count])
			# elements built now write the row
					
				tags_str =  ",".join(str(bit) for bit in influx_row_tags)
				fields_str = ",".join(str(bit) for bit in influx_row_fields)

				row_str = str(str(measurement) +',' + tags_str + ' ' + fields_str +' ' + str(influx_row_timestamp) + '\n')
				if args.verbose:
					print >> sys.stderr, 'row string is ' + row_str
				sys.stdout.write(row_str)
				#influx_writer.writerow(row_str)
		#Need to do ZCache so repeat above for zcache tables

		measurement = 'zcache'
		query = 'SELECT dev_types.dev_name, devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name, metering_zcache_info.data_dirty, metering_zcache_info.meta_dirty, ' +\
		'metering_zcache_info.data_clean, metering_zcache_info.meta_clean, metering_zcache_info.data_cb_util, metering_zcache_info.meta_cb_util, metering_zcache_info.data_read_hit, ' +\
		'metering_zcache_info.meta_read_hit, metering_zcache_info.data_write_hit, metering_zcache_info.meta_write_hit, metering_zcache_info."time" FROM metering_zcache_info ' +\
		'INNER JOIN devices ON (metering_zcache_info.dev_dbid = devices.dev_dbid) INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) WHERE 1 AND devices.dev_type = 7'
		if args.verbose:
			print >> sys.stderr, 'Execute zcache query'
			print >> sys.stderr, query

		cursor.execute(query + ';')

		influx_fields_tags = ['dev_name','dev_ext_name', 'dev_server_name', 'dev_target_name' ]
		influx_fields_fields  = ['data_dirty', 'meta_dirty','data_clean', 'meta_clean', 'data_cb_util', 'meta_cb_util', 'data_read_hit', 'meta_read_hit', 'data_write_hit', 'meta_write_hit']
		influx_fields = []
		for adds in influx_fields_tags:
			influx_fields.append(adds)
		for adds in influx_fields_fields:
			influx_fields.append(adds)

		# build line protocol sections for tags, fields and timestamp to match Influx Line Protocol https://docs.influxdata.com/influxdb/v1.1/write_protocols/line_protocol_tutorial/
		for sql_row in cursor:
			influx_row_timestamp = ""
			if len(sql_row) > 0:
				if args.verbose:
					print >> sys.stderr, str(sql_row)
				influx_row_tags = []
				influx_row_tags.append ('cloud_id=' + cloud_id)
				influx_row_tags.append('vpsa_id=' + vpsa_id)
				influx_row_fields = []
				sql_count = int(len(sql_row) -1)
						
				columns = len(influx_fields)
				#print >> sys.stderr, 'columns is ' + str(columns) + 'sql_row is ' + str(sql_count)
				if columns  == sql_count:

					columnid = 0
					
					for tkeys in influx_fields_tags:
						influx_row_tags.append(tkeys + '=' + str(sql_row[columnid]))
						if args.verbose:
							print >> sys.stderr, 'adding tag keys ' + str(tkeys) 

							print >> sys.stdout, columnid
						columnid = columnid +1
					for fkeys in influx_fields_fields:
						if (sql_row[columnid]) is None:
							influx_row_fields.append(fkeys + '=0')
						else:
							influx_row_fields.append(fkeys + '=' + str(sql_row[columnid]) +'i')
							columnid = columnid + 1
					influx_row_timestamp  = str(sql_row[sql_count])
			# elements built now write the row
					
				tags_str =  ",".join(str(bit) for bit in influx_row_tags)
				fields_str = ",".join(str(bit) for bit in influx_row_fields)

				row_str = str(str(measurement) +',' + tags_str + ' ' + fields_str +' ' + str(influx_row_timestamp) + '\n')
				if args.verbose:
					print >> sys.stderr, 'row string is ' + row_str
				sys.stdout.write(row_str)
				#influx_writer.writerow(row_str)




#query output for Elasticsearch timestamp first, searchable fields them metrics
elif output_type == 2 and dev_type_str == 'io':
	cursor.execute("""SELECT count(*) FROM sqlite_master where name = 'metering_info' and sql like('%total_resp_tm_ms%')""")
	ms_count = int(cursor.fetchone()[0])
	if ms_count > 0:
		query = 'SELECT devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name, io_buckets.bucket_name, dev_types.dev_name, ' +\
				'ROUND(CAST(metering_info.num_ios AS REAL) / interval, 3) AS iops, ROUND((CAST(metering_info.bytes AS REAL) / interval) / (1024 * 1024), 3) AS mbps, ' +\
				'ROUND(CAST(metering_info.total_resp_tm_ms AS REAL) / num_ios, 3) AS latency_ms, metering_info.active_ios, metering_info.io_errors, metering_info.max_cmd, ' +\
				'metering_info.max_resp_tm_ms AS max_latency_ms, metering_info.interval, metering_info.time AS unixtime ' +\
				'FROM  metering_info INNER JOIN devices ON (metering_info.dev_dbid = devices.dev_dbid) ' +\
				'INNER JOIN io_buckets ON (devices.dev_type = io_buckets.dev_type) AND (metering_info.bucket = io_buckets.bucket) ' +\
				'INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) AND (dev_types.dev_type = io_buckets.dev_type) ' +\
				'WHERE  '+ where + ' ' +\
				'ORDER BY metering_info.time'
	else:
		query = 'SELECT devices.dev_ext_name, devices.dev_server_name, devices.dev_target_name, io_buckets.bucket_name, dev_types.dev_name, ' +\
				'ROUND(CAST(metering_info.num_ios AS REAL) / interval, 3) AS iops, ROUND((CAST(metering_info.bytes AS REAL) / interval) / (1024 * 1024), 3) AS mbps, ' +\
				'ROUND(CAST((metering_info.total_resp_tm_us / 1000) AS real) / metering_info.num_ios, 3) AS latency_ms, metering_info.active_ios, metering_info.io_errors, metering_info.max_cmd, ' +\
				'ROUND(CAST((metering_info.max_resp_tm_us / 1000) AS real), 3) AS max_latency_ms, metering_info.interval, metering_info.time AS unixtime ' +\
				'FROM  metering_info INNER JOIN devices ON (metering_info.dev_dbid = devices.dev_dbid) ' +\
				'INNER JOIN io_buckets ON (devices.dev_type = io_buckets.dev_type) AND (metering_info.bucket = io_buckets.bucket) ' +\
				'INNER JOIN dev_types ON (devices.dev_type = dev_types.dev_type) AND (dev_types.dev_type = io_buckets.dev_type) ' +\
				'WHERE  '+ where + ' ' +\
				'ORDER BY metering_info.time'

#guery output for JSON format
elif output_type == 3 and dev_type_str == 'io':
#JSON dictionary fields
	json_fields_tags = ['dev_ext_name', 'dev_server_name', 'dev_target_name', 'bucket_name', 'dev_name']
	json_fields_fields  = ['iops', 'mbps', 'latency_ms', 'active_ios', 'io_errors', 'max_cmd', 'max_latency_ms', 'interval']
	json_fields  = json_fields_tags.copy()
	json_fields.update(json_fields_fields)

	json_writer = csv.DictWriter(sys.stdout,fieldnames=json_fields.keys())
	for sql_row in cursor:
		if len(sql_row) > 0:
			json_row_tags = {}
			json_row_fields = {}
			json_row_tags['cloud_id'] = cloud_id
			json_row_tags['vpsa_id'] =  vpsa_id


			columnid = 0
			while (columnid < len(sql_row)):
				for tkeys in json_fields_tags:
					json_row_tags[tkeys] = sql_row[columnid]
					columnid = columnid +1
				for fkeys in json_fields_fields:
					json_row_fields[fkeys] = sql_row[columnid]
					columnid = columnid +1
			json_row_timestamp  = sql_row[len(sql_row) -1]

#continue as normal and just create CSV file rolling up reads and writes into a single line
else: 
	query = 'SELECT devices.dev_dbid, dev_type, dev_ext_name, dev_server_name, dev_target_name, '	+ \
		'time AS unixtime, '																	+ \
		'DATE(time, ' + wanttime + ') AS date, '												+ \
		'TIME(time, ' + wanttime + ') AS time, '												+ \
		'interval, ' + fields + ' '																+ \
		'FROM (devices JOIN {0} ON devices.dev_dbid = {0}.dev_dbid) '.format(table)				+ \
		'WHERE ' + where + ' '																	+ \
		'ORDER BY dev_type, dev_ext_name, dev_server_name, dev_target_name, {0}.time '.format(table)

if args.verbose:
	print >> sys.stderr, 'Execute main query'
	print >> sys.stderr, query
cursor.execute(query + ';')

if args.verbose:
	print >> sys.stderr, 'Store as .csv'

# Store recordsets in csv format
if  output_type == 0 or output_type == 3:

	csv.register_dialect('excel_n', lineterminator='\n')
	writer = csv.DictWriter(sys.stdout, fieldnames, dialect='excel_n')

	header = dict()
	for f in fieldnames:
		header[f] = f
	writer.writerow(header)

	common_fieldnames_cnt = len(common_fieldnames)

	csv_row = dict()	
	prev_sql_row = list()
	for sql_row in cursor:

		if prev_sql_row[0:common_fieldnames_cnt] != sql_row[0:common_fieldnames_cnt]:
			if len(csv_row) > 0:
				writer.writerow(csv_row)
				csv_row.clear()
			for i in range(0, common_fieldnames_cnt):
				fname = common_fieldnames[i]
				csv_row[fname] = sql_row[i]
			dev_type_id = csv_row['dev_type']

		for dt in dev_types.items():
			if dev_type_id == dt[1]:
				csv_row['dev_type'] = dt[0]

		if dev_type_str == 'io':
			bucket_id = sql_row[common_fieldnames_cnt+0]
			bucket_name = io_buckets.get((dev_type_id, bucket_id))
			if bucket_name is not None:
				csv_row[bucket_name + '.iops'] = sql_row[common_fieldnames_cnt+1]
				csv_row[bucket_name + '.active_ios'] = sql_row[common_fieldnames_cnt+2]
				csv_row[bucket_name + '.io_errors'] = sql_row[common_fieldnames_cnt+3]
				csv_row[bucket_name + '.mbps'] = sql_row[common_fieldnames_cnt+4]
				csv_row[bucket_name + '.latency_ms'] = sql_row[common_fieldnames_cnt+5]
				csv_row[bucket_name + '.max_latency_ms'] = sql_row[common_fieldnames_cnt+6]
				csv_row[bucket_name + '.max_cmd'] = sql_row[common_fieldnames_cnt+7]
		elif dev_type_str == 'system':
			csv_row['cpu_user'] = sql_row[common_fieldnames_cnt+0]
			csv_row['cpu_system'] = sql_row[common_fieldnames_cnt+1]
			csv_row['cpu_iowait'] = sql_row[common_fieldnames_cnt+2]
			csv_row['cpu_idle'] = sql_row[common_fieldnames_cnt+3]
			csv_row['mem_used'] = sql_row[common_fieldnames_cnt+4]
			csv_row['mem_alloc'] = sql_row[common_fieldnames_cnt+5]
			csv_row['mem_active'] = sql_row[common_fieldnames_cnt+6]
	#dev_type == 'zcache'
		else:
			csv_row['data_dirty'] = sql_row[common_fieldnames_cnt+0]
			csv_row['meta_dirty'] = sql_row[common_fieldnames_cnt+1]
			csv_row['data_clean'] = sql_row[common_fieldnames_cnt+2]
			csv_row['meta_clean'] = sql_row[common_fieldnames_cnt+3]
			csv_row['data_cb_util'] = sql_row[common_fieldnames_cnt+4]
			csv_row['meta_cb_util'] = sql_row[common_fieldnames_cnt+5]
			csv_row['data_read_hit'] = sql_row[common_fieldnames_cnt+6]
			csv_row['meta_read_hit'] = sql_row[common_fieldnames_cnt+7]
			csv_row['data_write_hit'] = sql_row[common_fieldnames_cnt+8]
			csv_row['meta_write_hit'] = sql_row[common_fieldnames_cnt+9]

		prev_sql_row = sql_row

	# Write last row
	writer.writerow(csv_row)
	# write the file to go here....


