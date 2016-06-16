####Install logstash
	/usr/sfw/bin/wget https://download.elastic.co/logstash/logstash/logstash-2.3.1.tar.gz --no-check-certificate
	
	gunzip -c logstash-2.3.1.tar.gz | tar xvf -
	
	mv logstash-2.3.1 /usr/bin
	
	PATH=$PATH":/usr/bin/logstash-2.3.1/bin"
	
	edit the following file: /usr/bin/logstash-2.3.1/bin/logstash replace #!/bin/sh with #!/bin/bash
	
####Build configuration file for each log to be read from.
	See the examples logstash-rvngi.conf and logstash-rvngistats.conf
	
####Run logstash
	nohup logstash -f logstash*.conf &> /var/log/logstash.out &
	print $! >> /var/log/logstash-id
	If a directory is given, all files in that directory will be concatenated
	in lexicographical order and then parsed as a single config file. You can also specify
	wildcards (globs) and any matched files will be loaded in the order described above.