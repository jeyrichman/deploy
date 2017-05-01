import os
import time
import ConfigParser
import pymysql.cursors  # A pip-installed dependency
from ansible import utils
from ansible.module_utils import basic
from ansible.utils.unicode import to_unicode, to_bytes

config = ConfigParser.RawConfigParser()
config.read('/path/to/include/config.inc')
# This message will get concatenated to until it's time
# to log "flush" the message to the database
log_message = ''
task_id = ''

def banner(msg):
    """Output Trailing Stars"""
    width = 78 - len(msg)
    if width < 3:
        width = 3
    filler = "*" * width
    return "\n%s %s " % (msg, filler)

def append_to_log(msg):
    """Append message to log_message"""
    global log_message
    log_message += msg+"\n"

def flush_to_database(has_errors=False):
    """Save log_message to database"""
    global log_message
    log_type = 'info'

    if has_errors:
        log_type = 'error'
    
    db = pymysql.connect(host=config.get('global', 'db_host'),
                         user=config.get('global', 'db_username'),
                         passwd=config.get('global', 'db_password'),
                         db=config.get('global', 'db_name'),
                         charset='utf8mb4',
                         cursorclass=pymysql.cursors.DictCursor)

    with db.cursor() as cursor:
        sql = "INSERT INTO ansible_logs (ansible_task_id, date, log_type, log_message) VALUES (%s, %s, %s, %s)"

        current_time = time.strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute(sql, (
                task_id,
                current_time,
                log_type,
                log_message
            )
        )
        db.commit()

    db.close()
    log_message = ''

class CallbackModule(object):
    """
    An ansible callback module for saving Ansible output to a database log
    """

    def runner_on_failed(self, host, res, ignore_errors=False):
        results2 = res.copy()
        results2.pop('invocation', None)

        item = results2.get('item', None)

        if item:
            msg = "failed: [%s] => (item=%s) => %s" % (host, item, utils.jsonify(results2))
        else:
            msg = "failed: [%s] => %s" % (host, utils.jsonify(results2))

        append_to_log(msg)
        flush_to_database()

    def runner_on_ok(self, host, res):
        results2 = res.copy()
        results2.pop('invocation', None)

        item = results2.get('item', None)
        var = results2.get('var', None)

        changed = results2.get('changed', False)
        ok_or_changed = 'ok'
        if changed:
            ok_or_changed = 'changed'

        msg = "%s: [%s] => (item=%s)" % (ok_or_changed, host, item)
	if var:
	        msg += "%s: [%s] => (item=%s)" % (ok_or_changed, host, var)

        append_to_log(msg)
        flush_to_database()

    def runner_on_skipped(self, host, item=None):
        if item:
            msg = "skipping: [%s] => (item=%s)" % (host, item)
        else:
            msg = "skipping: [%s]" % host

        append_to_log(msg)
        flush_to_database()

    def runner_on_unreachable(self, host, res):
        item = None

        if type(res) == dict:
            item = res.get('item', None)
            if isinstance(item, unicode):
                item = utils.unicode.to_bytes(item)
            results = basic.json_dict_unicode_to_bytes(res)
        else:
            results = utils.unicode.to_bytes(res)
        host = utils.unicode.to_bytes(host)
        if item:
            msg = "fatal: [%s] => (item=%s) => %s" % (host, item, results)
        else:
            msg = "fatal: [%s] => %s" % (host, results)

        append_to_log(msg)
        flush_to_database()

    def runner_on_no_hosts(self):
        append_to_log("FATAL: no hosts matched or all hosts have already failed -- aborting")
        pass

    def playbook_on_task_start(self, name, is_conditional):
        name = utils.unicode.to_bytes(name)
        msg = "TASK: [%s]" % name
        if is_conditional:
            msg = "NOTIFIED: [%s]" % name

        append_to_log(banner(msg))

    def playbook_on_setup(self):
        append_to_log(banner('GATHERING FACTS'))
        pass

    def playbook_on_play_start(self, name):
        global task_id
        append_to_log(banner("PLAY [%s]" % name))

        hosts = self.playbook.inventory.get_hosts()
        host_vars = self.playbook.inventory.get_variables(hosts[0].name, self.playbook.vault_password)
        task_id = host_vars.get('task_id')

        pass

    def playbook_on_stats(self, stats):
        """Complete: Flush log to database"""
        has_errors = False
        hosts = stats.processed.keys()

        for h in hosts:
            t = stats.summarize(h)

            if t['failures'] > 0 or t['unreachable'] > 0:
                has_errors = True

            msg = "Host: %s, ok: %d, failures: %d, unreachable: %d, changed: %d, skipped: %d" % (h, t['ok'], t['failures'], t['unreachable'], t['changed'], t['skipped'])
            append_to_log(msg)

        flush_to_database(has_errors)
