#!/bin/bash

echo
echo "Starting ElasticSearch.... please wait"
echo
su -c "nohup /toolbox/elasticsearch-5.5.2/bin/elasticsearch -d -Enetwork.host=0.0.0.0 &>/toolbox/elasticsearch-5.5.2/elasticsearch.log &" -s /bin/bash elasticsearch
sleep 10
timeout 30 tail -f /toolbox/elasticsearch-5.5.2/logs/elasticsearch.log

echo
echo "Starting Kibana....please wait"
echo
su -c "nohup /toolbox/kibana-5.5.2-linux-x86_64/bin/kibana -c /toolbox/kibana.yml &>/toolbox/kibana-5.5.2-linux-x86_64/kibana.log &" -s /bin/bash elasticsearch
sleep 5
timeout 30 tail -f /toolbox/kibana-5.5.2-linux-x86_64/kibana.log


set -e

#command="$1 $2 $3";
command="$1"
script="$2"

if [[ "$command" == "python" && "$script" == "/toolbox/elasticsearch-gmail/src/index_emails.py" ]]; then
  echo
	echo "Launching Email Indexer....";
  echo

  # launch it!
  args=( "$@" )
  python /toolbox/elasticsearch-gmail/src/index_emails.py ${args[@]:2}

  echo ""
  echo "Email index is complete!"
  echo ""

elif [[ "$command" == "analyze-only" ]]; then
  echo
	echo "System started in analyze-only mode";
  echo

else
  echo
	echo "WARN: You should start with one of the following commands: "
  echo "   1. 'python /toolbox/elasticsearch-gmail/src/index_emails.py'";
  echo "   2. 'analyze-only' (default)";

  echo
  echo "System started in analyze-only mode";
  echo
fi

echo "In your web browser go to http://localhost:5601"
echo ""
echo "On the first screen that says 'Configure an index pattern', in the field labeled 'Index name or pattern' type 'mbox'"
echo "you will then see the 'date_ts' field auto-selected, then hit the 'Create' button. From there Kibana is ready to use!"
echo ""
echo "Kibana 5 tutorial: https://www.youtube.com/watch?v=mMhnGjp8oOI"
echo ""
echo "To quit the entire engine type ^C (cntrl C)"
echo ""

while true; do sleep 60; done
