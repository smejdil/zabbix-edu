/*
** Zabbix
** Copyright (C) 2001-2014 Zabbix SIA
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**
** Author: Cao Qingshan <caoqingshan@kingsoft.com>
**
** Version: 1.1 Last update: 2015-12-07 12:00
**
**/

#include "common.h"
#include "sysinc.h"
#include "module.h"
#include "cfg.h"
#include "log.h"
#include "zbxjson.h"
#include <mysql.h>
#include <errmsg.h>

#define ZBX_CFG_LTRIM_CHARS     "\t "
#define ZBX_CFG_RTRIM_CHARS     ZBX_CFG_LTRIM_CHARS "\r\n"

/* the variable keeps timeout setting for item processing */
static int	item_timeout = 0;

/* the path of config file */
static char	ZBX_MODULE_MYSQL_CONFIG_FILE[] = "/etc/zabbix/zbx_module_mysql.conf";

char		*CONFIG_MYSQL_INSTANCE_PORT = NULL;
char		*CONFIG_MYSQL_INSTANCE_USER = NULL;
char		*CONFIG_MYSQL_INSTANCE_PASSWORD = NULL;

static char	*MYSQL_DEFAULT_INSTANCE_HOST = "127.0.0.1";

int	zbx_module_mysql_load_config(int requirement);
int	zbx_module_mysql_is_number(char *result);
int	zbx_module_mysql_conn(MYSQL *mysql, char *db_host, char *db_user, char *db_pass, int db_port);
int	zbx_module_mysql_discovery(AGENT_REQUEST *request, AGENT_RESULT *result);
int	zbx_module_mysql_ping(AGENT_REQUEST *request, AGENT_RESULT *result);
int	zbx_module_mysql_version(AGENT_REQUEST *request, AGENT_RESULT *result);
int	zbx_module_mysql_status(AGENT_REQUEST *request, AGENT_RESULT *result);
int	zbx_module_mysql_slave_discovery(AGENT_REQUEST *request, AGENT_RESULT *result);
int	zbx_module_mysql_slave_status(AGENT_REQUEST *request, AGENT_RESULT *result);

static ZBX_METRIC keys[] =
/*	KEY				FLAG			FUNCTION				TEST PARAMETERS */
{
	{"mysql.discovery",	    	0,			zbx_module_mysql_discovery,		NULL},
	{"mysql.ping",			CF_HAVEPARAMS,		zbx_module_mysql_ping,			NULL},
	{"mysql.version",		CF_HAVEPARAMS,		zbx_module_mysql_version,		NULL},
	{"mysql.status",		CF_HAVEPARAMS,		zbx_module_mysql_status,	  	NULL},
	{"mysql.slave.discovery",	0,			zbx_module_mysql_slave_discovery,	NULL},
	{"mysql.slave.status",		CF_HAVEPARAMS,		zbx_module_mysql_slave_status,	  	NULL},
	{NULL}
};

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_api_version                                           *
 *                                                                            *
 * Purpose: returns version number of the module interface                    *
 *                                                                            *
 * Return value: ZBX_MODULE_API_VERSION_ONE - the only version supported by   *
 *               Zabbix currently                                             *
 *                                                                            *
 ******************************************************************************/
int	zbx_module_api_version()
{
	return ZBX_MODULE_API_VERSION_ONE;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_item_timeout                                          *
 *                                                                            *
 * Purpose: set timeout value for processing of items                         *
 *                                                                            *
 * Parameters: timeout - timeout in seconds, 0 - no timeout set               *
 *                                                                            *
 ******************************************************************************/
void	zbx_module_item_timeout(int timeout)
{
	item_timeout = timeout;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_item_list                                             *
 *                                                                            *
 * Purpose: returns list of item keys supported by the module                 *
 *                                                                            *
 * Return value: list of item keys                                            *
 *                                                                            *
 ******************************************************************************/
ZBX_METRIC	*zbx_module_item_list()
{
	return keys;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_mysql_load_config                                                  *
 *                                                                            *
 * Purpose: load configuration from config file                               *
 *                                                                            *
 * Parameters: requirement - produce error if config file missing or not      *
 *                                                                            *
 ******************************************************************************/
int zbx_module_mysql_load_config(int requirement)
{
	int	ret = SYSINFO_RET_FAIL;

	struct cfg_line cfg[] =
	{
		/* PARAMETER,           VAR,                                  TYPE,
			MANDATORY,  MIN,        MAX */
		{"mysql_inst_ports",    &CONFIG_MYSQL_INSTANCE_PORT,          TYPE_STRING_LIST,
			PARM_OPT,   0,          0},
		{"mysql_inst_user",     &CONFIG_MYSQL_INSTANCE_USER,          TYPE_STRING,
			PARM_OPT,   0,          0},
		{"mysql_inst_password", &CONFIG_MYSQL_INSTANCE_PASSWORD,      TYPE_STRING,
			PARM_OPT,   0,          0},
		{NULL}
	};

	parse_cfg_file(ZBX_MODULE_MYSQL_CONFIG_FILE, cfg, requirement, ZBX_CFG_STRICT);

	if (ZBX_CFG_FILE_REQUIRED == requirement && NULL == CONFIG_MYSQL_INSTANCE_PORT)
	{
		zabbix_log(LOG_LEVEL_WARNING, "Parameter mysql_inst_ports must be defined, example: 3306,3307:S");
		return ret;
	}

	else if (ZBX_CFG_FILE_REQUIRED == requirement && NULL == CONFIG_MYSQL_INSTANCE_USER)
	{
		zabbix_log(LOG_LEVEL_WARNING, "Parameter mysql_inst_user must be defined");
		return ret;
	}

	else if (ZBX_CFG_FILE_REQUIRED == requirement && NULL == CONFIG_MYSQL_INSTANCE_PASSWORD)
	{
		zabbix_log(LOG_LEVEL_WARNING, "Parameter mysql_inst_password must be defined");
		return ret;
	}

	else
	{
		ret = SYSINFO_RET_OK;
	}

	return ret;
}

int zbx_module_mysql_discovery(AGENT_REQUEST *request, AGENT_RESULT *result)
{
	char		*p;
	struct zbx_json	j;
	char		*port_list = NULL;
	char		*f = NULL;
	char		*s = NULL;
	char		*t = NULL;

	zbx_json_init(&j, ZBX_JSON_STAT_BUF_LEN);

	zbx_json_addarray(&j, ZBX_PROTO_TAG_DATA);
	
	/* for dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_discovery], CONFIG_MYSQL_INSTANCE_PORT value is: [%s]", CONFIG_MYSQL_INSTANCE_PORT);
	*/

	if (NULL != CONFIG_MYSQL_INSTANCE_PORT && '\0' != *CONFIG_MYSQL_INSTANCE_PORT)
	{
		port_list = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PORT);

		p = strtok(port_list, ",");
		while (NULL != p)
		{
			f = p;
			if (NULL == (s = strchr(p, ':'))) {
				zbx_lrtrim(f, ZBX_CFG_RTRIM_CHARS);
				zbx_json_addobject(&j, NULL);
				zbx_json_addstring(&j, "{#MYSQLHOST}", MYSQL_DEFAULT_INSTANCE_HOST, ZBX_JSON_TYPE_STRING);
				zbx_json_addstring(&j, "{#MYSQLPORT}", f, ZBX_JSON_TYPE_STRING);
				zbx_json_close(&j);
				/* for dev
				zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_discovery], add instance:[%s:%s] to discovery list", MYSQL_DEFAULT_INSTANCE_HOST, f);
				*/
			}
			else
			{
				*s++ = '\0';

				if (NULL == (t = strchr(s, ':'))) {
					zbx_lrtrim(f, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(s, ZBX_CFG_RTRIM_CHARS);

					if (0 == strcmp(s, "S"))
					{
						zbx_json_addobject(&j, NULL);
						zbx_json_addstring(&j, "{#MYSQLHOST}", MYSQL_DEFAULT_INSTANCE_HOST, ZBX_JSON_TYPE_STRING);
						zbx_json_addstring(&j, "{#MYSQLPORT}", f, ZBX_JSON_TYPE_STRING);
						zbx_json_close(&j);
						/* for dev
						zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_discovery], add instance:[%s:%s] to discovery list", MYSQL_DEFAULT_INSTANCE_HOST, f);
						*/
					}
					else {
						zbx_json_addobject(&j, NULL);
						zbx_json_addstring(&j, "{#MYSQLHOST}", f, ZBX_JSON_TYPE_STRING);
						zbx_json_addstring(&j, "{#MYSQLPORT}", s, ZBX_JSON_TYPE_STRING);
						zbx_json_close(&j);
						/* for dev
						zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_discovery], add instance:[%s:%s] to discovery list", f, s);
						*/
					}
				}
				else
				{
					*t++ = '\0';
					zbx_lrtrim(f, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(s, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(t, ZBX_CFG_RTRIM_CHARS);

					if (0 == strcmp(t, "S"))
					{
						zbx_json_addobject(&j, NULL);
						zbx_json_addstring(&j, "{#MYSQLHOST}", f, ZBX_JSON_TYPE_STRING);
						zbx_json_addstring(&j, "{#MYSQLPORT}", s, ZBX_JSON_TYPE_STRING);
						zbx_json_close(&j);
						/* for dev
						zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_discovery], add instance:[%s:%s] to discovery list", f, s);
						*/
					}
				}
			}
			p = strtok (NULL, ",");
		}
	}

	zbx_json_close(&j);

	SET_STR_RESULT(result, strdup(j.buffer));

	zbx_json_free(&j);

	return SYSINFO_RET_OK;

}

int zbx_module_mysql_slave_discovery(AGENT_REQUEST *request, AGENT_RESULT *result)
{
	char		*p;
	struct zbx_json	j;
	char		*port_list = NULL;
	char		*f = NULL;
	char		*s = NULL;
	char		*t = NULL;

	zbx_json_init(&j, ZBX_JSON_STAT_BUF_LEN);

	zbx_json_addarray(&j, ZBX_PROTO_TAG_DATA);
	
	/* for dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_slave_discovery], CONFIG_MYSQL_INSTANCE_PORT value is: [%s]", CONFIG_MYSQL_INSTANCE_PORT);
	*/

	if (NULL != CONFIG_MYSQL_INSTANCE_PORT && '\0' != *CONFIG_MYSQL_INSTANCE_PORT)
	{
		port_list = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PORT);

		p = strtok(port_list, ",");
		while (NULL != p)
		{
			f = p;
			if (NULL != (s = strchr(p, ':')))
			{
				*s++ = '\0';

				if (NULL != (t = strchr(s, ':')))
				{
					*t++ = '\0';
					zbx_lrtrim(f, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(s, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(t, ZBX_CFG_RTRIM_CHARS);
					if (0 == strcmp(t, "S"))
					{
						zbx_json_addobject(&j, NULL);
						zbx_json_addstring(&j, "{#MYSQLSLAVEHOST}", f, ZBX_JSON_TYPE_STRING);
						zbx_json_addstring(&j, "{#MYSQLSLAVEPORT}", s, ZBX_JSON_TYPE_STRING);
						zbx_json_close(&j);
						/* for dev
						zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_slave_discovery], add instance:[%s:%s] to discovery list", f, s);
						*/
					}
				}
				else
				{
					zbx_lrtrim(f, ZBX_CFG_RTRIM_CHARS);
					zbx_lrtrim(s, ZBX_CFG_RTRIM_CHARS);

					if (0 == strcmp(s, "S"))
					{
						zbx_json_addobject(&j, NULL);
						zbx_json_addstring(&j, "{#MYSQLSLAVEHOST}", MYSQL_DEFAULT_INSTANCE_HOST, ZBX_JSON_TYPE_STRING);
						zbx_json_addstring(&j, "{#MYSQLSLAVEPORT}", f, ZBX_JSON_TYPE_STRING);
						zbx_json_close(&j);
						/* for dev
						zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_slave_discovery], add instance:[%s:%s] to discovery list", MYSQL_DEFAULT_INSTANCE_HOST, f);
						*/
					}
				}
			}
			p = strtok (NULL, ",");
		}

	}

	zbx_json_close(&j);

	SET_STR_RESULT(result, strdup(j.buffer));

	zbx_json_free(&j);

	return SYSINFO_RET_OK;

}

int	zbx_module_mysql_is_number(char *result)
{
	int	ret = SYSINFO_RET_FAIL;
	char	*p;
	int	other_count = 0;

	if ('\0' != *result)
	{
		p = result;
		while ('\0' != *p)
		{
			if (0 == isdigit(*p)) 
			{
				other_count++;
			}
			p++;
		}

		if (other_count == 0)
		{
			ret = SYSINFO_RET_OK;
		}
	}

	return ret;
}

int	zbx_module_mysql_conn(MYSQL *mysql, char *db_host, char *db_user, char *db_pass, int db_port)
{
	int	ret = SYSINFO_RET_FAIL;

	char	*db, *db_socket;

	db = zbx_strdup(NULL, "");
	db_socket = zbx_strdup(NULL, "");

	/* initialize mysql  */
	mysql_init(mysql);

	/* establish a connection to the server and error checking */
	if (mysql_real_connect(mysql,db_host,db_user,db_pass,db,db_port,db_socket,0)) {
		ret = SYSINFO_RET_OK;
	}
	else
	{
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_conn], connect mysql server [%s:%d] using user [%s] fail: [%s]", db_host, db_port, db_user, mysql_error (mysql));
	}

	return ret;

}

int	zbx_module_mysql_version(AGENT_REQUEST *request, AGENT_RESULT *result)
{

	int		ret = SYSINFO_RET_FAIL;
	char		*db_user, *db_pass, *db_pass_no_log, *db_host, *str_db_port;
	unsigned int	db_port;
	MYSQL		mysql;
	unsigned long	version;
	char		value[10];

	db_user = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_USER);
	db_pass = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PASSWORD);
	db_pass_no_log = zbx_strdup(NULL, "***");

	if (request->nparam == 2)
	{
		db_host = get_rparam(request, 0);
		str_db_port = get_rparam(request, 1);
		db_port = atoi(str_db_port);
	}
	else if (request->nparam == 1)
	{
		db_host = MYSQL_DEFAULT_INSTANCE_HOST;
		str_db_port = get_rparam(request, 0);
		db_port = atoi(str_db_port);
	}
	else
	{
		/* set optional error message */
		SET_MSG_RESULT(result, zbx_strdup(NULL, "Invalid number of parameters"));
		return ret;
	}

	/* dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_version], args:[%s,%s,%s,%d]", db_host, db_user, db_pass_no_log, db_port);
	*/

	if (SYSINFO_RET_OK != zbx_module_mysql_conn(&mysql,db_host,db_user,db_pass,db_port)) {
		SET_MSG_RESULT(result, zbx_strdup(NULL, "Can't connect to mysql server"));
		return ret;
	}

	version = mysql_get_server_version(&mysql);

	zbx_snprintf(value, 10, "%d.%d.%d", version/10000, (version%10000)/100, (version%10000)%100);

	SET_STR_RESULT(result, zbx_strdup(NULL, value));

	ret = SYSINFO_RET_OK;

	mysql_close(&mysql);

	return ret;
}

int	zbx_module_mysql_ping(AGENT_REQUEST *request, AGENT_RESULT *result)
{

	char		*db_user, *db_pass, *db_pass_no_log, *db_host, *str_db_port;
	unsigned int	db_port;
	MYSQL		mysql;

	db_user = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_USER);
	db_pass = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PASSWORD);
	db_pass_no_log = zbx_strdup(NULL, "***");

	if (request->nparam == 2)
	{
		db_host = get_rparam(request, 0);
		str_db_port = get_rparam(request, 1);
		db_port = atoi(str_db_port);
	}
	else if (request->nparam == 1)
	{
		db_host = MYSQL_DEFAULT_INSTANCE_HOST;
		str_db_port = get_rparam(request, 0);
		db_port = atoi(str_db_port);
	}
	else
	{
		/* set optional error message */
		SET_MSG_RESULT(result, zbx_strdup(NULL, "Invalid number of parameters"));
		return SYSINFO_RET_FAIL;
	}

	/* for dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_ping], args:[%s,%s,%s,%d]", db_host, db_user, db_pass_no_log, db_port);
	*/

	if (SYSINFO_RET_OK == zbx_module_mysql_conn(&mysql,db_host,db_user,db_pass,db_port)) {
		SET_UI64_RESULT(result, 1);
	}
	else
	{
		SET_UI64_RESULT(result, 0);
	}

	mysql_close(&mysql);

	return SYSINFO_RET_OK;
}

int	zbx_module_mysql_status(AGENT_REQUEST *request, AGENT_RESULT *result)
{
	int		ret = SYSINFO_RET_FAIL;
	char		*db_user, *db_pass, *db_pass_no_log, *db_host, *str_db_port, *key;
	zbx_uint64_t	value;
	unsigned int	db_port;
	int		find = 0;

	MYSQL		mysql;
	MYSQL_RES	*res;
	MYSQL_ROW	row;

	char		*error = NULL;

	db_user = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_USER);
	db_pass = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PASSWORD);
	db_pass_no_log = zbx_strdup(NULL, "***");

	if (request->nparam == 3)
	{
		db_host = get_rparam(request, 0);
		str_db_port = get_rparam(request, 1);
		db_port = atoi(str_db_port);
		key = get_rparam(request, 2);
	}
	else if (request->nparam == 2)
	{
		db_host = MYSQL_DEFAULT_INSTANCE_HOST;
		str_db_port = get_rparam(request, 0);
		db_port = atoi(str_db_port);
		key = get_rparam(request, 1);
	}
	else
	{
		/* set optional error message */
		SET_MSG_RESULT(result, zbx_strdup(NULL, "Invalid number of parameters"));
		return ret;
	}

	/* for dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_status], args: [%s,%s,%s,%d,%s]", db_host, db_user, db_pass_no_log, db_port, key);
	*/

	if (SYSINFO_RET_OK != zbx_module_mysql_conn(&mysql,db_host,db_user,db_pass,db_port)) {
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		return ret;
	}

	if (mysql_query(&mysql, "show global status")) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_status], exec sql [show global status] error: [%s]", zbx_strdup(NULL, mysql_error(&mysql)));
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		mysql_close (&mysql);
		return ret;
	}

	if ((res = mysql_store_result (&mysql)) == NULL) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_status], result store error: [%s]", zbx_strdup(NULL, mysql_error(&mysql)));
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		mysql_close (&mysql);
		return ret;
	}

	while ((row = mysql_fetch_row (res)) != NULL) {
		if (strcmp(row[0], key) == 0) {
			find = 1;
			if (row[1]) {
				if (SYSINFO_RET_OK == zbx_module_mysql_is_number(row[0])) {
					/* for dev
					zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_status], args [%s:%d], find key:[%s] value:[%d]", db_host, db_port, key, row[1]);
					*/
					sscanf(row[1], ZBX_FS_UI64, &value);
					SET_UI64_RESULT(result, value);
					ret = SYSINFO_RET_OK;
				}
				else {
					/* for dev
					zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_status], args [%s:%d], find key:[%s] value:[%s]", db_host, db_port, key, row[1]);
					*/
					SET_STR_RESULT(result, zbx_strdup(NULL, row[1]));
					ret = SYSINFO_RET_OK;
				}
			}
			else {
				/* for dev
				zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_status], args [%s:%d], find key:[%s] value:[NULL]", db_host, db_port, key);
				*/
				SET_STR_RESULT(result, zbx_strdup(NULL, "NULL"));
				ret = SYSINFO_RET_OK;
			}
		}
	}

	mysql_free_result(res);
	mysql_close(&mysql);

	if (find != 1)
	{
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_status], can't find key: [%s]", key);
		SET_MSG_RESULT(result, zbx_dsprintf(NULL, "Not supported key [%s]", key));
	}

	return ret;
}

int	zbx_module_mysql_slave_status(AGENT_REQUEST *request, AGENT_RESULT *result)
{
	int		ret = SYSINFO_RET_FAIL;
	char		*db_user, *db_pass, *db_pass_no_log, *db_host, *str_db_port, *key;
	zbx_uint64_t	value;
	unsigned int	db_port;
	int		i, num_fields;
	int		find = 0;

	MYSQL		mysql;
	MYSQL_RES	*res;
	MYSQL_ROW	row;
	MYSQL_FIELD	*fields;

	char		*error = NULL;

	db_user = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_USER);
	db_pass = zbx_strdup(NULL, CONFIG_MYSQL_INSTANCE_PASSWORD);
	db_pass_no_log = zbx_strdup(NULL, "***");

	if (request->nparam == 3)
	{
		db_host = get_rparam(request, 0);
		str_db_port = get_rparam(request, 1);
		db_port = atoi(str_db_port);
		key = get_rparam(request, 2);
	}
	else if (request->nparam == 2)
	{
		db_host = MYSQL_DEFAULT_INSTANCE_HOST;
		str_db_port = get_rparam(request, 0);
		db_port = atoi(str_db_port);
		key = get_rparam(request, 1);
	}
	else
	{
		/* set optional error message */
		SET_MSG_RESULT(result, zbx_strdup(NULL, "Invalid number of parameters"));
		return ret;
	}

	/* for dev
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_mysql_slave_status], args: [%s,%s,%s,%d,%s]", db_host, CONFIG_MYSQL_INSTANCE_USER, db_pass_no_log, db_port, key);
	*/

	if (SYSINFO_RET_OK != zbx_module_mysql_conn(&mysql,db_host,db_user,db_pass,db_port)) {
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		return ret;
	}

	if (mysql_query(&mysql, "show slave status")) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_slave_status], exec sql [show slave status] error: [%s]", zbx_strdup(NULL, mysql_error(&mysql)));
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		mysql_close (&mysql);
		return ret;
	}

	if ( (res = mysql_store_result (&mysql)) == NULL) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_slave_status], result store error: [%s]", zbx_strdup(NULL, mysql_error(&mysql)));
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		mysql_close (&mysql);
		return ret;
	}
    
	if (mysql_num_rows(res) == 0) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_slave_status], error: [no slaves defined]");
		SET_MSG_RESULT(result, zbx_strdup(NULL, "No slave defined"));
		mysql_free_result (res);
		mysql_close(&mysql);
		return ret;
	}

	/* fetch the first row */
	if ( (row = mysql_fetch_row (res)) == NULL) {
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_slave_status], slave fetch row error: [%s]", zbx_strdup(NULL, mysql_error(&mysql)));
		SET_MSG_RESULT(result, zbx_strdup(NULL, mysql_error(&mysql)));
		mysql_free_result (res);
		mysql_close (&mysql);
		return ret;
	}

	num_fields = mysql_num_fields(res);
	fields = mysql_fetch_fields(res);
	for(i = 0; i < num_fields; i++) {
		if (strcmp(fields[i].name, key) == 0) {
			find = 1;
			if (row[i]) {
				if (SYSINFO_RET_OK == zbx_module_mysql_is_number(row[i])) {
					sscanf(row[i], ZBX_FS_UI64, &value);
					SET_UI64_RESULT(result, value);
					ret = SYSINFO_RET_OK;
				}
				else {
					SET_STR_RESULT(result, zbx_strdup(NULL, row[i]));
					ret = SYSINFO_RET_OK;
				}
			}
			else {
				SET_STR_RESULT(result, zbx_strdup(NULL, "NULL"));
				ret = SYSINFO_RET_OK;
			}
		}
	}

	mysql_free_result(res);
	mysql_close(&mysql);

	if (find != 1)
	{
		zabbix_log(LOG_LEVEL_WARNING, "module [mysql], func [zbx_module_mysql_slave_status], can't find key: [%s]", key);
		SET_MSG_RESULT(result, zbx_dsprintf(NULL, "Not supported key [%s]", key));
	}

	return ret;

}

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_init                                                  *
 *                                                                            *
 * Purpose: the function is called on agent startup                           *
 *          It should be used to call any initialization routines             *
 *                                                                            *
 * Return value: ZBX_MODULE_OK - success                                      *
 *               ZBX_MODULE_FAIL - module initialization failed               *
 *                                                                            *
 * Comment: the module won't be loaded in case of ZBX_MODULE_FAIL             *
 *                                                                            *
 ******************************************************************************/
int	zbx_module_init()
{
	zabbix_log(LOG_LEVEL_INFORMATION, "module [mysql], func [zbx_module_init], using configuration file: [%s]", ZBX_MODULE_MYSQL_CONFIG_FILE);
	if (SYSINFO_RET_OK != zbx_module_mysql_load_config(ZBX_CFG_FILE_REQUIRED))
		return ZBX_MODULE_FAIL;

	return ZBX_MODULE_OK;
}

/******************************************************************************
 *                                                                            *
 * Function: zbx_module_uninit                                                *
 *                                                                            *
 * Purpose: the function is called on agent shutdown                          *
 *          It should be used to cleanup used resources if there are any      *
 *                                                                            *
 * Return value: ZBX_MODULE_OK - success                                      *
 *               ZBX_MODULE_FAIL - function failed                            *
 *                                                                            *
 ******************************************************************************/
int	zbx_module_uninit()
{
	return ZBX_MODULE_OK;
}
