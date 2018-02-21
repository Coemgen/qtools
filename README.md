# Dependencies

- dart
- gzip
- git

# Crontab 

Example crontab to find new q posts
```
*/5 * * * * dart /path_to_q_tools/bin/post_checker.dart >> /var/log/q_tools.log 2>&1
```
