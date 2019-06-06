{% set backup_user = 'backup_user'  %}
{% set backup_user_password = ''  %} # move to vault
{% set backup_host_fqdn = '' %}
{% set backup_host_short = '' %}
{% set backup_dir = '/backup' %}
{% set backup_report_output = 'log' %}
{% set backup_report_email = '' %}
{% set backup_cron_hour = '20' %}
{% set backup_cron_minute = '30' %}
{% set backup_fs_mount = '0' %}
{% set smtp_relayhost = '' %}
{% set backup_user_password_file = '/data/db01/mysql01/backups/config/backup_user.pwd' %}
{% set db_to_backup = 'coshh' %}

Install MySQL-python:
  pkg.installed: 
    - skip_verify: True
    - pkgs:
       - MySQL-python

backup_user:
  mysql_user.present:
    - host: {{ backup_user }}
    - password: {{ backup_user_password }}

#backup_user_all_db:
#   mysql_grants.present:
#    - grant:  select,update
#    - database: coshh.*
#    - user: backup_user
#    - host: localhost

#coshh:
#   mysql_query.run:
#    - database: coshh
#    - query: "GRANT  SELECT,INSERT,UPDATE,CREATE,DROP,RELOAD,SHUTDOWN,ALTER,SUPER,LOCK TABLES,REPLICATION CLIENT ON *.* to backup_user@localhost"
#    - output: /tmp/coshh.txt

extract_scripts:
  archive.extracted:
    - name: /data/db01/mysql01/backups
    - source: salt://mysql-backup/mysql-backup-scripts.tar.gz
    - archive_format: tar
    - if_missing: /data/db01/mysql01/backups

/backup:
  file.directory:
    - user: mysql
    - group: mysql
    - if_missing: /backup

/data/db01/mysql01/backups/config/backup_user.pwd:
  file.managed:
    - source: salt://mysql-backup/backup_user.pwd.j2         
    - template: jinja
    - user: mysql
    - group: mysql
    - mode: '0644'
    - context:
        backup_user_password: {{ backup_user_password }}

/data/db01/mysql01/backups/config/myserver.conf:
  file.managed:
    - source: salt://mysql-backup/myserver.conf.j2         
    - template: jinja
    - user: mysql
    - group: mysql
    - mode: '0644'
    - context:
        backup_user: {{ backup_user }}
        backup_host_fqdn: {{ backup_host_fqdn }}
        backup_host_short: {{ backup_host_short }}
        backup_dir: {{ backup_dir }}
        backup_report_output: {{ backup_report_output }}
        backup_report_email: {{ backup_report_email }}
        backup_user_password_file: {{ backup_user_password_file }}
        db_to_backup: {{ db_to_backup }}

/data/db01/mysql01/backups/config/backup_tasks.conf:
  file.managed:
    - source: salt://mysql-backup/backup_tasks.conf.j2         
    - template: jinja
    - user: mysql
    - group: mysql
    - mode: '0644'
    - context:
        backup_fs_mount: {{ backup_fs_mount }}
        backup_report_email: {{ backup_report_email }}
        backup_dir: {{ backup_dir }}


/etc/postfix/main.cf:
  file.managed:
    - source: salt://mysql-backup/main.cf.j2         
    - template: jinja
    - user: root
    - group: root
    - mode: '0644'
    - context:
        smtp_relayhost: {{ smtp_relayhost }}

/etc/crontab:
  file.managed:
    - source: salt://mysql-backup/crontab
    - user: root 
    - group: root 
    - mode: '0644'


postfix:
  service: 
    - running
    - watch:
      - file: /etc/postfix/main.cf


crond:
  service: 
    - running
    - watch:
      - file: /etc/crontab


Test the backup:
  cmd.run:
    - name: /data/db01/mysql01/backups/bin/automysqlbackup -bc /data/db01/mysql01/backups/config/myserver.conf  
    - cwd: /root
